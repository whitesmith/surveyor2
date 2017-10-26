module Surveyor
  module SurveysControllerMethods
    def index
      @surveys = Surveyor::Survey.order(created_at: :desc, survey_version: :desc)
    end

    def show
      @survey = Surveyor::Survey.find(params[:id])
    end

    def answer
      # TODO
    end
  end
end
