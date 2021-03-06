class ApplicationController < ActionController::Base
  include FastGettext::Translation
  include SimpleCaptcha::ControllerHelpers
  require 'uri'
  require 'set'
  helper :all

  protect_from_forgery

  before_filter :sidebar_variables
  before_filter :get_locale
  before_filter :https_for_admins
  before_filter :set_start_time, :set_time_zone, :set_view_items, :current_ability
  before_filter :log_additional_data, :set_per_page
  after_filter  :auto_login_admin_user
  after_filter  :store_location
  after_filter  :log_session


  def check_params_encoding
    if params[:id] && !params[:id].valid_encoding?
      tagged_logger("Security", "Invalid encoding on params[:id]", :info)
      redirect_to root_path
    else
      true
    end
  end

  def sidebar_variables
    @site_categories   ||= Category.order("priority ASC, title DESC")
    @site_pages        ||= Page.active.order("priority ASC")
    @private_pages     ||= Page.active.member_only.order("priority ASC")
    @site_languages    ||= Language.order("locale ASC")
    @site_country_tags ||= CountryTag.order("title ASC")
    @site_general_tags ||= GeneralTag.order("title ASC")
    @site_region_tags  ||= RegionTag.order("title ASC")
    @site_links        ||= Link.order("title ASC")
  end

  def no_cache_for_admin
    if current_user or request[:controller].to_s.match("admin|users|comments|devise")
      private_headers
    end
  end

  def get_locale
    subdomain = extract_locale_from_subdomain
    if subdomain
      extracted_locale = extract_locale_from_subdomain
      I18n.locale = extracted_locale
      FastGettext.locale = extracted_locale
      session[:locale] = extracted_locale
    else
      set_default_locale
    end
    tagged_logger("Locale", "FastGettext=#{FastGettext.locale} I18n=#{I18n.locale.to_s}")
  end

  def redirect_to_default_domain(str)
    if str.match(default_locale)
      new_host = str.gsub("#{default_locale}\.",'')
      redirect_to "#{request.host}#{new_host}"
    end
  end

  # Get locale code from request subdomain (like http://it.application.local:3000)
  # You have to put something like:
  #   127.0.0.1 gr.application.local
  # in your /etc/hosts file to try this out locally
  def extract_locale_from_subdomain
    parsed_locale = request.subdomains.first
    if parsed_locale && locale_available?(parsed_locale.to_s)
      tagged_logger("Locale", "From subdomain to '#{parsed_locale}'")
      parsed_locale
    else
      nil
    end
  end

  # Get locale from top-level domain or return nil if such locale is not available
  # You have to put something like:
  #   127.0.0.1 application.com
  #   127.0.0.1 application.it
  #   127.0.0.1 application.pl
  # in your /etc/hosts file to try this out locally
  def extract_locale_from_tld
    parsed_locale = request.host.to_s.split('.').last
    I18n.available_locales.include?(parsed_locale.to_sym) ? parsed_locale  : nil
  end

  def default_locale
    'en'
  end

  def set_default_locale
    FastGettext.locale = default_locale
    I18n.locale = default_locale.to_sym
    session[:locale] = default_locale
  end

  def locale_provided?
    params[:locale] && locale_available?(params[:locale].to_s)
  end

  def locale_available?(str)
    str.match('(ar|de|en|es|fr|it|nl|pt|ru)')
  end

  def set_locale_from_session
    FastGettext.locale = session[:locale]
    I18n.locale = session[:locale].to_sym
  end

  def using_ssl?
    request.protocol == "https://"
  end

  def set_locale_from_params
    FastGettext.locale = params[:locale]
    I18n.locale = params[:locale].to_sym
    session[:locale] = params[:locale].to_sym
  end

  def should_use_to_https?
    (current_user or current_admin_user) && ( !request.method.match("POST") && !request.url.match("auth")) or request.url.match("/admin/login$")
  end

  def https_for_admins
    if Rails.env.production? && should_use_to_https? && !using_ssl?
      tagged_logger("Admin", "Redirecting to HTTPS", :info)
      redirect_to request.url.gsub("http://", "https://")
      # Warning! Need to have this in Nginx https config block
      # proxy_set_header X_FORWARDED_PROTO https;
    end
  end

  def auto_login_admin_user
    if current_admin_user && !current_user
      tagged_logger("Admin", "Auto sign-in for AdminUser: #{current_admin_user.id}", :info)
      sign_in(:user, current_admin_user, bypass: true)
    end
  end

  comment_destroy_conditions do |comment|
    comment.owner == current_user
  end

  def logged_in?
    (current_user or current_admin_user)
  end

  def should_cache?
    if (view_context.is_bot? or request.format.to_s.match("(rss|atom|xml)")) && !logged_in?
     true
    else
     false
    end
  end

  def headers_with_timeout(timeout)
    if should_cache?
      public_headers(timeout)
    else
      private_headers
    end
  end

  def private_headers
    if current_user
      no_cache_headers
    else
      private_headers_with_timeout
    end
  end

  def no_cache_headers
    tagged_logger("Caching", "no-cache, private", :info)
    headers['Cache-Control'] = 'no-cache, private'
  end

  def private_headers_with_timeout(timeout=600)
    tagged_logger("Caching", "private, must-revalidate, max-age=#{timeout}", :info)
    headers['Cache-Control'] = "private, must-revalidate, max-age=#{timeout}"
  end

  def public_headers(timeout=900)
    tagged_logger("Caching", "public, max-age=#{timeout}")
    headers['Cache-Control'] = "public, max-age=#{timeout}"
    if @last_published && @last_published.respond_to?(:httpdate)
      headers['Last-Modified'] = @last_published.httpdate
    end
    headers['X-Accel-Expires'] = timeout
    headers['Etag'] = @etag if @etag
  end

  def headers_for_etag(etag=nil)
    headers['Etag'] = etag if etag
  end

  def last_modified
    if @last_published.nil? && (@last_item = Item.last_item)
      @last_published = @last_item.last_modified.httpdate
    else
      @last_published = Time.now.httpdate
    end
  end

  def set_per_page
    if params[:per_page]
      @per_page = params[:per_page].to_i
    end
  end

  def set_start_time
    @start_time = Time.now.usec
  end

  def current_ability
    if current_admin_user
      @current_ability ||= Ability.new(current_admin_user)
    elsif current_user
      @current_ability ||= Ability.new(current_user)
    else
      @current_ability ||= Ability.new(User.new) 
    end
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to admin_dashboard_path(protocol: http_protocol), alert: exception.message
  end

  def default_per_page
    24
  end

  def per_page
    if params[:per_page] && params[:per_page].to_s.match("[0-9]{1,}")
      @per_page = params[:per_page].to_s.to_i
    else
      @per_page = default_per_page
    end
    @per_page
  end

  def page
    if params[:page] && params[:page].to_s.match("[0-9]{1,}")
      page = params[:page].to_i
    else
      page = 1
    end
  end

  

  def set_view_items
    unless session[:view_items]
      session[:view_items] = Set.new
    end
  end

  def set_time_zone
    if current_user && current_user.time_zone
      tagged_logger("Timezone", current_user.time_zone)
      Time.zone = current_user.time_zone
    elsif current_admin_user && current_admin_user.time_zone
      tagged_logger("Timezone", current_admin_user.time_zone)
      Time.zone = current_admin_user.time_zone
    end
  end

  def http_protocol
    if Rails.env.production?
      'https'
    else
      'http'
    end
  end

  # temporarily use mobile by setting by URL
  def get_layout
    if params[:mobile_mode] or session[:mobile_mode] == "1"
      session[:mobile_mode] = "1"
      layout_name = "mobile"
    elsif params[:desktop_mode]
      session[:mobile_mode] = nil
      layout_name = "items"
    else
      layout_name = "items"
    end
    return "items"
  end


  def opensearch
    response.headers['Content-Type'] = 'application/opensearchdescription+xml; charset=utf-8'
  end

  # Customize the Devise after_sign_in_path_for() for redirecct to previous page after login
  def after_sign_in_path_for(resource_or_scope)
    case resource_or_scope
    when :admin_user, AdminUser
      redirect_location
    when :user, User
      redirect_location
    else
      super
    end
  end

  def redirect_location
    if current_user && current_user.email.match("please_update_your_email")
      edit_user_registration_path(protocol: http_protocol)
    else
      redirect_url
    end
  end

  def tagged_logger(tag,msg,level=:debug)
    if level == :info
      Rails.logger.tagged(tag) { Rails.logger.info(msg) }
    elsif level == :warn
      Rails.logger.tagged(tag) { Rails.logger.warn(msg) }
    else
      Rails.logger.tagged(tag) { Rails.logger.debug(msg) }
    end
  end

  def not_found
    raise ActiveRecord::RecordNotFound.new('Not Found')
  end

  unless Rails.application.config.consider_all_requests_local
    rescue_from Exception, with: lambda { |exception| render_error_and_notify 500, exception }
    rescue_from ActionController::RoutingError,
      ActionController::UnknownController,
      ::AbstractController::ActionNotFound,
      ActiveRecord::RecordNotFound,
      with: lambda { |exception| render_error 404, exception }
  end

  def render_error(status, exception)
    respond_to do |format|
      format.html { render template: "errors/error_#{status}", layout: 'layouts/simple', status: status }
      format.all { render nothing: true, status: status }
    end
  end

  def render_error_and_notify(status, exception)
    ExceptionNotifier::Notifier.exception_notification(request.env, exception).deliver
    render_error(status, exception)
  end

  ### PRIVATE METHODS ###
  protected

    def redirect_url
      if request.env['omniauth.origin']
        request.env['omniauth.origin']
      elsif session[:return_to].present? && session[:return_to].match("items")
        session[:return_to]
      else
        root_path
      end
    end

    def store_location
      session[:return_to] = request.fullpath
    end

    def clear_stored_location
      session[:return_to] = nil
    end

    def log_session
      tagged_logger("Session", session.inspect) if Rails.env.development?
    end

    def log_additional_data
      request.env["exception_notifier.exception_data"] = {
        current_user: current_user
      } if current_user
      request.env["exception_notifier.exception_data"] = {
        current_admin_user: current_admin_user
      } if current_admin_user
    end

    def user_for_paper_trail
      if admin_user_signed_in?
        current_admin_user
      elsif user_signed_in?
        current_user
      else
        "Unknown user"
      end
    end
  
end
