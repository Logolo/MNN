ActiveAdmin.register_page "Drafts" do
  menu priority: 2, label: "Drafts", parent: "Dashboard"
  action_item do
    link_to "Website", "/"
  end
  content title: "Draft Articles" do
    if authorized?(:read, Item)
      panel "Draft Articles" do
        render 'drafts'
      end
    end
  end
end

ActiveAdmin.register_page "Recent Page Views" do
  menu priority: 2, label: "Recent Page Views", parent: "Dashboard"
  action_item do
    link_to "Website", "/"
  end
  content title: "Recent Page Views" do
    if authorized?(:read, PageView)
      panel "Recent Page Views (updated every 5 minutes)" do
        cache_expiring("aa/page_views", 5.minutes) do
          render "page_views"
        end
      end
    end
  end
end

ActiveAdmin.register_page "Database History" do
  menu priority: 2, label: "Database History", parent: "Dashboard"
  action_item do
    link_to "Website", "/"
  end
  content title: "Database History" do
    if authorized?(:read, Version)
      panel "Database History" do
        render 'history'
      end
    end
  end
end

ActiveAdmin.register_page "User Stats" do
  menu priority: 9, label: "User Stats", parent: "Dashboard"
  action_item do
    link_to "Website", "/"
  end
  content title: "User Stats" do
    if authorized?(:read, User)
      panel "Recently Logged in Users (updated every 5 minutes)" do
        cache_expiring("aa/logged_users", 5.minutes) do
          render 'logged_users'
        end
      end
      panel "Recently Registered Users (updated every 5 minutes)" do
        cache_expiring("aa/registered_users", 5.minutes) do
          render 'registered_users'
        end
      end
    end
  end
end

ActiveAdmin.register_page "Popular Searches" do
  menu priority: 2, label: "Popular Searches", parent: "Dashboard"
  action_item do
    link_to "Website", "/"
  end
  content title: "Popular Searches" do
    if authorized?(:read, SearchQuery)
      panel "Popular Searches (updated every 10 minutes)" do
        cache_expiring("aa/popular_searches", 10.minutes) do
          render 'popular_searches'
        end
      end
    end
  end
end

ActiveAdmin.register_page "DB Stats" do
  menu priority: 2, label: "DB Stats", parent: "Dashboard"
  action_item do
    link_to "Website", "/"
  end
  content title: "Database Statistics" do
    cache_expiring("aa/db_stats", 10.minutes) do
      render "db_stats"
    end
  end
end

ActiveAdmin.register_page "Charts" do
  menu priority: 2, label: "Charts", parent: "Dashboard"
  action_item do
    link_to "Website", "/"
  end
  content do
    cache_expiring("aa/charts", 12.hours) do
      render "charts"
    end
  end
end
