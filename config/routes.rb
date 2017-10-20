Surveyor::Engine.routes.draw do
  get '/',    to: 'surveys#index',  as: 'surveys'
  get '/:id', to: 'surveys#show',   as: 'survey'
  put '/:id', to: 'surveys#answer', as: 'answer_survey'
end
