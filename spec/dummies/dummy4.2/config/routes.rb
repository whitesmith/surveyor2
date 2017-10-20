Rails.application.routes.draw do
  mount Surveyor::Engine => '/surveys', as: 'surveyor'
end
