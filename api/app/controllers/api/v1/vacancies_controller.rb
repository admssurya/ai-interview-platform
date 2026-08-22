# frozen_string_literal: true

module Api
  module V1
    class VacanciesController < ApiController
      authorize_auth_token! :assessor

      before_action :set_vacancy, only: %i[show update destroy]

      # GET /api/v1/vacancies
      def index
        vacancies = paginate(Vacancy.order(created_at: :desc))

        json_response(
          vacancies: serialize(vacancies, with: VacancySerializer),
          meta: pagination_meta(vacancies)
        )
      end

      # GET /api/v1/vacancies/:id
      def show
        json_response(vacancy: serialize(@vacancy, with: VacancySerializer, with_skills: true, taxonomy_map: taxonomy_map_for(@vacancy)))
      end

      # POST /api/v1/vacancies
      def create
        vacancy = Vacancy.new(vacancy_params)
        vacancy.created_by = current_user.id

        if vacancy.save
          json_response({ vacancy: serialize(vacancy, with: VacancySerializer, with_skills: true, taxonomy_map: taxonomy_map_for(vacancy)) }, :created)
        else
          json_error(vacancy.errors.full_messages.first, :unprocessable_entity)
        end
      end

      # PUT /api/v1/vacancies/:id
      def update
        if @vacancy.update(vacancy_params)
          json_response(vacancy: serialize(@vacancy, with: VacancySerializer, with_skills: true, taxonomy_map: taxonomy_map_for(@vacancy)))
        else
          json_error(@vacancy.errors.full_messages.first, :unprocessable_entity)
        end
      end

      # DELETE /api/v1/vacancies/:id
      def destroy
        @vacancy.destroy
        json_response(message: "Vacancy deleted")
      end

      private

      def set_vacancy
        @vacancy = Vacancy.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        json_error("Vacancy not found", :not_found)
      end

      def vacancy_params
        params.require(:vacancy).permit(
          :role_title,
          :culture_dimensions,
          :competency_expectations,
          vacancy_skills_attributes: %i[
            id skill_id skill_label expected_level _destroy
          ]
        )
      end

      # Preload taxonomy anchors in one query to avoid N+1.
      def taxonomy_map_for(vacancy)
        skill_ids = vacancy.vacancy_skills.filter_map(&:skill_id).uniq
        SkillTaxonomy.where(skill_id: skill_ids).index_by(&:skill_id)
      end

      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          total_pages:  collection.total_pages,
          total_count:  collection.total_count,
          per_page:     collection.limit_value
        }
      end
    end
  end
end
