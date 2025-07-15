# frozen_string_literal: true

Rails.application.routes.draw do
  mount ActionCable.server => '/cable'

  root 'home#home'
  get 'info', to: 'home#info', as: :info
  get 'disseminators', to: 'home#disseminators', as: :disseminators
  get 'help', to: 'home#help', as: :help
  get 'help_assessment', to: 'home#help_assessment', as: :help_assessment
  get 'changelogs', to: 'home#changelogs', as: :changelogs

  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions',
  }

  resources :wko, only: %i[show]

  namespace :competitions do
    resource :creations, only: %i[new create]
  end
  scope '/:year/:slug', constraints: { year: /(\d{4})/ }, module: :competitions, as: :competition do
    root 'showings#show', as: :show
    resource :editing, only: %i[edit update]
    resource :visibility, only: %i[edit update]
    resource :registration, only: %i[edit update]
    resource :deletion, only: %i[new create]
    resource :duplication, only: %i[new create]
    resource :unlocking, only: %i[new create]
    resources :documents, only: %i[new create edit update destroy]
    get 'dd/:idpart', to: 'documents#download', as: :document_download
    get 'dp/:idpart', to: 'documents#preview', as: :document_preview
    get 'di/:idpart', to: 'documents#image', as: :document_image
    resource :publishing, only: %i[new create]
    resources :information_requests, only: %i[new create]

    # top menu
    resources :teams, only: %i[new create show edit update index] do
      member do
        get :edit_assessment_requests
        resource :deletion, only: %i[new create], as: :team_deletion, controller: :team_deletions
      end
      collection do
        get :without_statistics_connection
      end
      resources :markers, only: %i[edit update], controller: :team_marker_values
      resources :accesses, only: %i[index destroy], controller: :user_team_accesses
      resources :access_requests, only: %i[new create destroy], controller: :user_team_access_requests do
        member { get :connect }
      end
    end
    resources :team_markers, only: %i[new create index edit update destroy]
    resource :team_marker_block_values, only: %i[edit update]
    resources :team_list_restrictions, only: %i[new create index edit update destroy]
    resource :team_import, only: %i[new create]
    resources :people do
      member do
        get :edit_assessment_requests
      end
      collection do
        get :without_statistics_connection
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
          get 'edit_entity/:entry_id', action: :edit_entity, as: :edit_entity
          get 'destroy_entity/:entry_id', action: :destroy_entity, as: :destroy_entity
          get :edit_times
          get :list_conditions
        end
        resources :runs, only: %i[edit update], param: :run
      end
      resources :results
      resources :competition_results
      resources :list_print_generators, only: %i[index new show edit update destroy]
      resources :list_conditions, only: %i[new create edit update destroy]
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
      resources :imports, only: %i[new create]
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

    resources :accesses, only: %i[index edit destroy]
    resources :access_requests, only: %i[new create destroy] do
      member { get :connect }
    end
    resources :simple_accesses, only: %i[new create destroy]
    resource :simple_access_login, only: %i[new create destroy]
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
