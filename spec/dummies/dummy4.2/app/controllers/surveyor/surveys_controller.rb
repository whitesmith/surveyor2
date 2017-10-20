class Surveyor::SurveysController < Surveyor::ApplicationController
  def index
    @surveys = Survey.order(created_at: :desc, survey_version: :desc)
  end

  def show
    @surveys = Survey.find(params[:id])
  end

  def answer
    # TODO
  end
end
