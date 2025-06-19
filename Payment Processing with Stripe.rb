# app/services/payment_processor.rb
class PaymentProcessor
  class PaymentError < StandardError; end

  def initialize(user)
    @user = user
    Stripe.api_key = ENV['STRIPE_SECRET_KEY']
  end

  def create_customer
    customer = Stripe::Customer.create(
      email: @user.email,
      metadata: { user_id: @user.id }
    )
    @user.update(stripe_customer_id: customer.id)
    customer
  rescue Stripe::StripeError => e
    raise PaymentError, e.message
  end

  def create_subscription(plan_id)
    customer = @user.stripe_customer_id || create_customer.id
    subscription = Stripe::Subscription.create(
      customer: customer,
      items: [{ plan: plan_id }],
      expand: ['latest_invoice.payment_intent']
    )
    
    Subscription.create!(
      user: @user,
      stripe_id: subscription.id,
      status: subscription.status,
      plan_id: plan_id,
      current_period_end: Time.at(subscription.current_period_end)
    )
    
    subscription
  rescue Stripe::StripeError => e
    raise PaymentError, e.message
  end

  def handle_webhook(event)
    case event.type
    when 'invoice.payment_succeeded'
      handle_payment_succeeded(event.data.object)
    when 'customer.subscription.deleted'
      handle_subscription_cancelled(event.data.object)
    end
  end

  private

  def handle_payment_succeeded(invoice)
    subscription = Subscription.find_by(stripe_id: invoice.subscription)
    return unless subscription

    subscription.update(
      status: 'active',
      current_period_end: Time.at(invoice.lines.data.first.period.end)
    )
  end

  def handle_subscription_cancelled(subscription)
    subscription = Subscription.find_by(stripe_id: subscription.id)
    subscription&.update(status: 'canceled')
  end
end

# app/controllers/api/v1/payments_controller.rb
class Api::V1::PaymentsController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :verify_subscription_privileges, only: [:create_subscription]

  def create_customer
    processor = PaymentProcessor.new(current_user)
    customer = processor.create_customer
    render json: { customer: customer }
  rescue PaymentProcessor::PaymentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def create_subscription
    processor = PaymentProcessor.new(current_user)
    subscription = processor.create_subscription(params[:plan_id])
    
    render json: { subscription: subscription }
  rescue PaymentProcessor::PaymentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def webhook
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, ENV['STRIPE_WEBHOOK_SECRET']
      )
    rescue JSON::ParserError => e
      render json: { error: e.message }, status: :bad_request
      return
    rescue Stripe::SignatureVerificationError => e
      render json: { error: e.message }, status: :bad_request
      return
    end

    PaymentProcessor.new(nil).handle_webhook(event)
    head :ok
  end

  private

  def verify_subscription_privileges
    unless current_user.can_create_subscription?
      render json: { error: 'Subscription not allowed' }, status: :forbidden
    end
  end
end
