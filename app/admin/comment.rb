ActiveAdmin.register Comment do
  config.clear_sidebar_sections!
  menu priority: 8, label: "Comments"

  index title: "Comments" do
    selectable_column
    column "Item ID", sortable: :commentable_id do |t|
      link_to t.commentable_id, item_path(t.commentable_id) if t.commentable_id
    end
    column "User", sortable: :owner_id do |t|
      if t.owner
        link_to t.owner.title, admin_user_path(t.owner), class: "suspicious_#{t.suspicious?} spam_#{t.marked_spam?}"
      end
    end
    column "Message", sortable: false do |t|
      link_to sanitize(t.body, tags: '', attributes: '').truncate(65),
        admin_comment_path(t),
        title: sanitize(t.body, tags: '', attributes: '').truncate(300),
        class: "suspicious_#{t.suspicious?} spam_#{t.marked_spam?}"
    end
    column "Moderator", :approving_user
    column "Live", :approved do |t|
      bool_symbol t.approved
    end
    column "Spam", :marked_spam do |t|
      bool_symbol t.marked_spam
    end
    column "Created", :created_at do |t|
      time_ago_in_words(t.created_at) + " ago"
    end
    column "Updated", :created_at do |t|
      time_ago_in_words(t.updated_at) + " ago"
    end
    default_actions
  end

  form do |f|
    f.inputs 'Editing Comment' do
      f.input :body, as: :text, input_html: {rows: 5}
      f.input :approved
      f.input :marked_spam
      f.input :suspicious
      f.input :approving_user, as: :select, collection: AdminUser.moderators.order("id ASC").map{ |t| [ t.title, t.id ] }, include_blank: true
      f.input :skip_spam_check, as: :boolean, hint: "Check this to bypass spam checking, to avoid false positives."
    end
    f.buttons
  end


  show title: :display_name do
    attributes_table do
      row "Item" do |t|
        link_to t.commentable_id, item_path(t.commentable_id) if t.commentable_id
      end
      row "User", &->(t){link_to_if t.owner, t.display_name, admin_user_path(t.owner_id)}
      row :user_ip, &->(t){link_to(t.user_ip, "http://www.geoiptool.com/en/?IP=#{t.user_ip}", target: "_blank")}
      row :user_agent
      bool_row :approved
      bool_row "Spam", &:marked_spam
      bool_row :suspicious
      row :created_at
      row :updated_at
      row 'Comment' do |comment|
        sanitize comment.body,
          tags: comment.allowed_html_tags,
          attributes: comment.allowed_html_attributes
      end
      row 'Comment HTML', &->(t){t.body}
    end
  end
  
  controller do
    def destroy
      @comment = Comment.find(params[:id])
      authorize! :destroy, @comment
      @old_id = @comment.id
      @comment.destroy if @comment
      respond_to do |format|
        format.html {redirect_to admin_comments_path}
        format.js {render layout: false}
        format.json
      end
    end
    def scoped_collection
      Comment.includes(:owner)
    end
    rescue_from CanCan::AccessDenied do |exception|
      redirect_to admin_authorization_denied_path, alert: exception.message
    end
  end
  
end
