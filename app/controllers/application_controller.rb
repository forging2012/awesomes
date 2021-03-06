class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def current_mem
    Mem.find_by_id(session[:mem])  
  end

  def admin_login
    #true
    redirect_to "/" and return if session[:mem] != 1
  end

  def mem_login
    #true
    redirect_to "/" and return if !current_mem
  end

  def is_me?
    _id = params[:id].to_i 
    if _id > 0
      @mem = Mem.find_by_id _id
      redirect_to '/tip',:notice=> t('mem_none') and return if !@mem 
    else
      redirect_to '/tip',:notice=> t('no_login') and return  if session[:mem].to_i < 1
      @mem = current_mem
    end
    #redirect_to '/tip',:notice=> t('mem_novalid') and return if @mem.recsts == '1'
    @isme = (@mem == current_mem)
  end

  def repo_lost
    @item = @repo = Repo.find_by({:owner=> params[:owner],:alia=> params[:alia]})
  end

  def doc_lost
    @item = @doc = Doc.find_by_name(params[:typ])
  end

  def docsub_lost
    @item = @sub = Docsub.find_by_id(params[:id])
  end

  def readme_lost
    @item = Readme.find_by_id(params[:id]) 
  end

  def comment_lost
    @item = Comment.find(params[:id])
    render json: {status: false} and return if @item.mem != current_mem
  end
  
  def category_lost 
     @item = Menutyp.where({:key=> params[:typ],:typcd=> 'B'}).first
  end

  def max_page_size
    100
  end
    
  def default_page_size
    15
  end

  def page_size
    size = params[:pagesize].to_i
    [size.zero? ? default_page_size : size, max_page_size].min
  end

  def page
    @page = params[:page]
    @page = 1 if !@page
    @page =  @page.to_i - 1
  end

  def data_list query
    query.order('id desc').limit(page_size).offset(page * page_size)
  end

  def data_list_asc query
    query.order('id asc').limit(page_size).offset(page * page_size)
  end

  def upload_pic(file,filename,folder,width,height)
    _full_path = "#{Rails.root}/public/upload/#{folder}/#{filename}"
    image = MiniMagick::Image.read(file)
    if width.to_i > 0 and height.to_i > 0
      _width = image[:width]
      _height = image[:height]
      _x = 0
      _y = 0
      if width / height > _width / _height
        image.resize "#{width}x"
        _y = ((image[:height] - height) / 3.0 * 2).to_i
      else
        image.resize "x#{height}"
        _x = ((image[:width] - width) / 2.0).to_i
      end
      image.crop "#{width}x#{height}+#{_x}+#{_y}"
    end
    image.write  _full_path
    FileUtils.chmod 0755, _full_path
    return _full_path
  end

  def aliyun_upload file,target
    _connection = CarrierWave::Storage::Aliyun::Connection.new({
      :aliyun_access_id=> ENV['OSS_ACCESS_ID'],
      :aliyun_access_key=> ENV['OSS_ACCESS_KEY'],
      :aliyun_bucket=> ENV['OSS_BUCKET'],
      :aliyun_area=> ENV['OSS_AREA'],
      :aliyun_upload_host=> ENV['OSS_UPLOAD_HOST']
    })
    _connection.put(target, file)
  end

  def upload_remote(remote_src,filename,dir)
    require 'open-uri' 
    web_contents  = open(remote_src).read
    aliyun_upload web_contents,"#{dir}/#{filename}"
  end

  def clear_fragment key
    ActionController::Base.new.expire_fragment(key)
  end

end
