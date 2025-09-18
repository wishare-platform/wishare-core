class Admin::UrlCacheController < Admin::BaseController
  before_action :require_admin
  before_action :find_cache_entry, only: [:show, :refresh, :destroy]

  def index
    @stats = UrlMetadataCache.statistics
    @caches = UrlMetadataCache.includes(:created_at)

    # Filtering
    @caches = @caches.by_platform(params[:platform]) if params[:platform].present?
    @caches = @caches.popular if params[:popular] == 'true'
    @caches = @caches.expired if params[:expired] == 'true'
    @caches = @caches.valid if params[:valid] == 'true'

    # Sorting
    case params[:sort]
    when 'hits'
      @caches = @caches.most_popular
    when 'recent'
      @caches = @caches.recently_accessed
    when 'created'
      @caches = @caches.order(created_at: :desc)
    else
      @caches = @caches.order(hit_count: :desc)
    end

    @caches = @caches.page(params[:page]).per(50)

    respond_to do |format|
      format.html
      format.json { render json: @stats }
    end
  end

  def show
    @metadata = @cache_entry.to_metadata
  end

  def refresh
    @cache_entry.refresh!
    redirect_to admin_url_cache_index_path, notice: "Cache refresh queued for #{@cache_entry.url}"
  end

  def destroy
    url = @cache_entry.url
    @cache_entry.destroy
    redirect_to admin_url_cache_index_path, notice: "Cache entry deleted for #{url}"
  end

  def cleanup
    UrlMetadataCache.cleanup!
    redirect_to admin_url_cache_index_path, notice: "Cache cleanup completed"
  end

  def warm
    count = UrlMetadataCache.popular.expired.count
    UrlMetadataCache.warm_cache_for_popular_items
    redirect_to admin_url_cache_index_path, notice: "Warming #{count} popular cache entries"
  end

  def clear_all
    if request.post? && params[:confirm] == 'true'
      count = UrlMetadataCache.count
      UrlMetadataCache.destroy_all
      Rails.cache.delete_matched("url_metadata:*")
      redirect_to admin_url_cache_index_path, notice: "Cleared #{count} cache entries"
    else
      redirect_to admin_url_cache_index_path, alert: "Confirmation required to clear cache"
    end
  end

  private

  def find_cache_entry
    @cache_entry = UrlMetadataCache.find(params[:id])
  end

  def require_admin
    redirect_to root_path unless current_user&.admin?
  end
end