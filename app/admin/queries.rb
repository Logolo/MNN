ActiveAdmin.register Query do
  config.clear_sidebar_sections!
  controller.authorize_resource
  config.sort_order = "created_at_desc"
  menu parent: "Items", label: 'Site Searches', priority: 10, if: lambda{|tabs_renderer|
    controller.current_ability.can?(:read, Query)
  }
  actions :index
  config.comments = false
  index do
    column "Search Term", sortable: :keyword do |t|
      link_to t.keyword.to_s, search_path(q: t.keyword.to_s), target: "_blank"
    end
    column "Details", sortable: false do |t|
      pp t.raw_data
    end
    column "Language", :locale
    column "User", sortable: :user_id do |t|
      link_to t.user.public_display_name, admin_user_path(t.user) if t.user
    end
    column "Date", sortable: :created_at do |t|
      t.created_at.to_s(:long) if t.created_at
    end
  end
  controller do
    def scoped_collection
       Query.includes(:item, :user)
    end
  end
end
