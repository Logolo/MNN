ActiveAdmin.register Item do
  config.sort_order = "id_desc"
  config.per_page = 12
  action_item only: [:show, :edit] do
    link_to('View on site', item_path(item))
  end

  scope :published
  scope :highlight
  scope :sticky
  scope :original
  scope :draft
  scope :with_comments
  scope :queued
  scope :from_youtube

  # Filters
  filter :category
  filter :language
  filter :user, collection: proc { AdminUser.with_articles.order("id ASC").all }
  filter :title, label: "Headline"
  filter :abstract
  filter :author_name
  filter :youtube_id, label: "Youtube ID"
  filter :draft
  filter :original
  filter :featured, label: "Highlight"
  filter :sticky
  filter :created_at
  filter :updated_at
  filter :published_at

  menu priority: 1, parent: 'Items', label: 'All Items'
  sidebar :per_page, partial: "per_page", only: :index

  before_filter only: :index do
    if params[:per_page]
      @per_page = params[:per_page].to_i
      @per_page = 100 if @per_page > 100
    end
  end

  show do
    render "show"
  end
  index title: "Items" do
    id_column
    column :image do |item|
      if item.has_image?
        link_to(
          image_tag(item.main_image.image.thumb.url),
          admin_item_path(item),
          title: item.abstract,
        )
      elsif item.youtube_id && item.youtube_img
        link_to(
          image_tag("https://img.youtube.com/vi/#{item.youtube_id}/1.jpg",
            class:"youtube_mini"
          ),
          admin_item_path(item),
          title: "Youtube ID: #{item.youtube_id}"
        )
      end
    end
    column :user
    column "Title", sortable: :title do |item|
      link_to item.title, admin_item_path(item), title: item.abstract, class: "featured_#{item.featured}"
    end
    column :category, sortable: :category_id
    column "Views", sortable: false do |item|
      item.item_stat.views_counter if item.item_stat
    end
    column "Orig", :original, sortable: :original do |item|
      bool_symbol(item.original)
    end
    column "Highlt", :featured, sortable: :featured do |item|
      bool_symbol(item.featured)
    end
    bool_column :sticky
    column "Live", sortable: :published_at do |item|
      if !item.draft? && item.published_at && item.published_at > Time.zone.now
        ("<span class='red bold'>" +
        time_ago_in_words(item.published_at) +
        " from now" +
        '</span>').html_safe
      elsif !item.draft? && item.published_at
        ("<span class='green bold'>" +
        time_ago_in_words(item.published_at) +
        " ago" +
        '</span>').html_safe
      elsif item.draft
        "<b><i>Draft</i></b>".html_safe
      else
        item.published_at.localtime.to_s(:short)
      end
    end
    column "", sortable: false do |item|
      link_to("Live Preview", item, 'data-no-turbolink' => true) if controller.current_ability.can?(:preview, item)
    end
    column "", sortable: false do |item|
      link_to "Details", admin_item_path(item) if controller.current_ability.can?(:preview, item)
    end
    column "" do |item|
      link_to "Edit", edit_admin_item_path(item) if controller.current_ability.can?(:update, item)
    end
    column "" do |item|
      if controller.current_ability.can?(:destroy, item)
        link_to "Delete", admin_item_path(item), method: :delete, data: {confirm: "Are you sure you want to delete this article entirely?"}
      end
    end

    #default_actions
  end
  form partial: "form"

  controller do
    include ActionView::Helpers::SanitizeHelper
    def new
      authorize! :create, Item
      @item = Item.new
      @now = Time.zone.now
      @item.published_at = nil
      @published_at = nil
      @item.draft = true
      @item.user_id = current_admin_user.id
      if params[:feed_id]
        @feed_entry = FeedEntry.find(params[:feed_id])
        @item.title = sanitize(@feed_entry.title, tags: '', attributes: '').to_s.truncate(96) if @feed_entry.title.present?
        @item.source_url = @feed_entry.url if @feed_entry.url.present?
        @item.author_name = @feed_entry.author if @feed_entry.author.present?
        @item.abstract = sanitize(@feed_entry.summary, tags: '', attributes: '').to_s.truncate(116) if @feed_entry.summary.present?
        @item.body = @feed_entry.content if @feed_entry.content.present?
      end
    end

    def show
      @item = Item.includes(:user, :attachments, :tags).find(params[:id])
      if params[:version].present? && params[:version].match("[0-9]{1,}")
        tagged_logger("ADMIN", "Reifying to version: #{params[:version]}", :info)
        @item = @item.versions[params[:version].to_i].reify
      end
      authorize! :read, @item
    end

    def edit
      @item = Item.find(params[:id])
      lock_version = @item.lock_version if @item
      if params[:version].present? && params[:version].match("[0-9]{1,}")
        tagged_logger("ADMIN", "Reifying to version: #{params[:version]}", :info)
        @item = @item.versions[params[:version].to_i].reify
        @item.lock_version = lock_version
      end

      authorize! :edit, @item

      if @item.published_at
        @published_at = @item.published_at.strftime "%Y-%m-%d %H:%M:%S %z"
      else
        @published_at = Time.now.to_s
      end
    end

    def update
      @item = Item.find(params[:id])
      authorize! :edit, @item
      if @item.update_attributes(params[:item])
        flash[:notice] = "Successfully updated Item."
        redirect_to @item
      else
        render action: 'edit'
      end

    rescue ActiveRecord::StaleObjectError
      correct_stale_record_version
      stale_record_recovery_action
    end

    def create
      @item = Item.new(params[:item])
      @item.user_id = current_admin_user.id
      authorize! :create, @item
      unless (current_admin_user.has_any_role?(:admin,:editor,:security))
        @item.draft = true
        @item.share_twitter = nil
        @item.send_emails = nil
      end
      respond_to do |format|
        if @item.save
          format.html { redirect_to admin_item_path(@item), notice: 'Item was successfully created.' }
          format.json { render json: @item, status: :created, location: @item }
        else
          format.html { render action: "new" }
          format.json { render json: @item.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @item = Item.find(params[:id])
      authorize! :destroy, @item
      if (current_admin_user.has_any_role?(:admin,:editor,:security)) or (current_admin_user.id == @item.user_id)
        @item.destroy
        flash[:notice] = "Item successfully deleted"
      else
        flash[:notice] = "You are not allowed to delete this Item"
      end
      respond_to do |format|
        format.html {redirect_to admin_items_path}
        format.js {render layout: false}
        format.json
      end
    end

    def correct_stale_record_version
      @item.reload
    end

    def stale_record_recovery_action
      flash[:error] = "Error: Another user has updated this record since you accessed the edit form."
      render :edit, status: :conflict
    end

    def scoped_collection
      Item.includes(:language, :attachments, :tags, :user, :category, :item_stat).reduced
    end
    rescue_from CanCan::AccessDenied do |exception|
      redirect_to admin_authorization_denied_path, alert: exception.message
    end
  end
end
