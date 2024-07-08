# frozen_string_literal: true

Rails.application.routes.draw do
  root 'home#home'
  get 'info', to: 'home#info', as: :info

  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions',
  }

  namespace :competitions do
    resource :creations, only: %i[new create]
  end
  scope '/:year/:slug', constraints: { year: /(\d{4})/ }, module: :competitions, as: :competition do
    root 'showings#show', as: :show
    resource :editing, only: %i[edit update]
    resource :visibility, only: %i[edit update]
    resource :registration, only: %i[edit update]
    resource :deletion, only: %i[new create]
    resources :documents, only: %i[new create edit update destroy]

    # top menu
    resources :teams do
      member do
        get :edit_assessment_requests
      end
    end
    resource :team_import, only: %i[new create]
    resources :people do
      member do
        get :edit_assessment_requests
      end
    end
    namespace :score do
      resource :list_factories, only: %i[new create edit update destroy] do
        collection { get 'copy_list/:list_id', action: :copy_list, as: :copy_list }
      end
      resources :lists, only: %i[show edit update index destroy] do
        member do
          get :move
          post :move
          get :select_entity
          get 'destroy_entity/:entry_id', action: :destroy_entity, as: :destroy_entity
          get :edit_times
        end
        resources :runs, only: %i[edit update], param: :run
      end
      resources :results
      resources :competition_results
      resources :list_print_generators, only: %i[index new show edit update destroy]
    end

    namespace :series do
      resources :rounds, only: %i[index show]
      resources :assessments, only: [:show]
    end

    # wrench menu
    resources :disciplines
    resources :bands
    resources :assessments

    namespace :certificates do
      resources :templates do
        member do
          get :edit_text_fields
          get :duplicate
          get :remove_file
        end
      end
      resources :lists, only: %i[new create] do
        collection do
          get :export
        end
      end
    end

    resources :accesses, only: [:index]
    resources :access_requests, only: %i[new create destroy] do
      member { get :connect }
    end
    resources :presets, only: %i[index edit update]
  end

  namespace :fire_sport_statistics do
    namespace :suggestions do
      post :people
      post :teams
    end
  end

  get 'not_found', to: 'errors#not_found'
  get 'internal_server_error', to: 'errors#internal_server_error'
  get 'unprocessable_entity', to: 'errors#unprocessable_entity'
end
