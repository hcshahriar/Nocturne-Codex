# app/graphql/types/query_type.rb
module Types
  class QueryType < Types::BaseObject
    field :projects, [Types::ProjectType], null: false,
      description: "Returns a list of projects"

    field :project, Types::ProjectType, null: true do
      description "Find a project by ID"
      argument :id, ID, required: true
    end

    def projects
      Project.accessible_by(context[:current_ability])
    end

    def project(id:)
      project = Project.find(id)
      authorize! :read, project
      project
    rescue ActiveRecord::RecordNotFound
      raise GraphQL::ExecutionError, "Project not found"
    end
  end
end

# app/controllers/api/graphql_controller.rb
class Api::GraphqlController < ApplicationController
  before_action :authenticate_user!

  def execute
    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = {
      current_user: current_user,
      current_ability: current_ability
    }
    result = DarkForgeSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?
    handle_error_in_development e
  end

  private

  def current_ability
    @current_ability ||= Ability.new(current_user)
  end

  # Handle form data, JSON body, or a blank value
  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      if ambiguous_param.present?
        ensure_hash(JSON.parse(ambiguous_param))
      else
        {}
      end
    when Hash, ActionController::Parameters
      ambiguous_param
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end

  def handle_error_in_development(e)
    logger.error e.message
    logger.error e.backtrace.join("\n")

    render json: { errors: [{ message: e.message, backtrace: e.backtrace }], data: {} }, status: 500
  end
end
