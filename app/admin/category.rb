ActiveAdmin.register Category do
  config.sort_order = "priority_asc"
  menu parent: "More", priority: 80, label: "Categories"
  index title: "Categories" do
    id_column
    column :title
    column :description
    column :priority
    bool_column :active
    column "Last Item" do |category|
      if category.last_item
        if category.last_item.published_at < 4.days.ago
          css_class = "red"
        else
          css_class = "green"
        end
        ("<span class='#{css_class} bold'>" +
        time_ago_in_words(category.last_item.published_at) +
        " ago" +
        '</span>').html_safe
      end
    end
    column "Updated" do |category|
      category.updated_at.to_s(:short)
    end
    default_actions
  end
  controller do
    rescue_from CanCan::AccessDenied do |exception|
      redirect_to admin_authorization_denied_path, alert: exception.message
    end
  end
end
