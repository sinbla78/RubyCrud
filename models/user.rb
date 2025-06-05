# Gemfile
# gem 'sinatra'
# gem 'json'

require 'sinatra'
require 'json'
require_relative '../models/user'

class UserManager
  def initialize
    @users = []
    @next_id = 1
  end
  
  # Create - 새 사용자 생성 (API 버전)
  def create_user(name, email, age, created_by: "system")
    current_time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    
    user = User.new(
      id: @next_id,
      name: name,
      email: email,
      age: age,
      created_by: created_by,
      created_at: current_time,
      updated_at: current_time
    )
    
    unless user.valid?
      return { success: false, error: "유효하지 않은 사용자 정보입니다.", data: nil }
    end
    
    @users << user
    @next_id += 1
    { success: true, message: "사용자가 성공적으로 생성되었습니다.", data: user.to_hash }
  end
  
  # Read - 모든 사용자 조회 (API 버전)
  def read_all_users
    {
      success: true,
      message: "모든 사용자 조회 완료",
      count: @users.length,
      data: @users.map(&:to_hash)
    }
  end
  
  # Read - 특정 사용자 조회 (ID로)
  def read_user_by_id(id)
    user = @users.find { |u| u.id == id }
    if user
      { success: true, message: "사용자를 찾았습니다.", data: user.to_hash }
    else
      { success: false, error: "ID #{id}인 사용자를 찾을 수 없습니다.", data: nil }
    end
  end
  
  # Update - 사용자 정보 수정
  def update_user(id, name: nil, email: nil, age: nil, updated_by: "system")
    user = @users.find { |u| u.id == id }
    
    if user.nil?
      return { success: false, error: "ID #{id}인 사용자를 찾을 수 없습니다.", data: nil }
    end
    
    # 업데이트할 필드들 설정
    user.name = name if name
    user.email = email if email
    user.age = age if age
    user.updated_at = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    
    unless user.valid?
      return { success: false, error: "수정된 정보가 유효하지 않습니다.", data: nil }
    end
    
    { success: true, message: "사용자 정보가 수정되었습니다.", data: user.to_hash }
  end
  
  # Delete - 사용자 삭제
  def delete_user(id)
    user_index = @users.find_index { |u| u.id == id }
    
    if user_index.nil?
      return { success: false, error: "ID #{id}인 사용자를 찾을 수 없습니다.", data: nil }
    end
    
    deleted_user = @users.delete_at(user_index)
    { success: true, message: "사용자가 삭제되었습니다.", data: deleted_user.to_hash }
  end
  
  # 검색 기능 - 이름으로 사용자 찾기
  def search_users_by_name(name)
    found_users = @users.select { |u| u.name.downcase.include?(name.downcase) }
    
    {
      success: true,
      message: "'#{name}'으로 검색 완료",
      count: found_users.length,
      data: found_users.map(&:to_hash)
    }
  end
  
  # 통계 정보
  def get_stats
    total_users = @users.length
    avg_age = total_users > 0 ? @users.sum(&:age) / total_users.to_f : 0
    
    {
      success: true,
      message: "통계 조회 완료",
      data: {
        total_users: total_users,
        average_age: avg_age.round(1)
      }
    }
  end
  
  # 사용자 존재 여부 확인
  def user_exists?(id)
    @users.any? { |u| u.id == id }
  end
end

# Sinatra API 애플리케이션
class UserAPI < Sinatra::Base
  
  def initialize
    super
    @user_manager = UserManager.new
    
    # 테스트용 더미 데이터 추가
    @user_manager.create_user("홍길동", "hong@example.com", 25, created_by: "admin")
    @user_manager.create_user("김영희", "kim@example.com", 30, created_by: "admin")
  end
  
  # CORS 설정 (프론트엔드와 연동할 때 필요)
  before do
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    content_type :json
  end
  
  # OPTIONS 요청 처리 (CORS preflight)
  options '*' do
    200
  end
  
  # 에러 핸들링
  error do
    status 500
    { success: false, error: "서버 내부 오류가 발생했습니다." }.to_json
  end
  
  # GET /users - 모든 사용자 조회
  get '/users' do
    result = @user_manager.read_all_users
    status 200
    result.to_json
  end
  
  # GET /users/:id - 특정 사용자 조회
  get '/users/:id' do
    id = params[:id].to_i
    result = @user_manager.read_user_by_id(id)
    
    if result[:success]
      status 200
    else
      status 404
    end
    
    result.to_json
  end
  
  # POST /users - 새 사용자 생성
  post '/users' do
    begin
      # JSON 파싱
      request_payload = JSON.parse(request.body.read)
      name = request_payload['name']
      email = request_payload['email']
      age = request_payload['age']
      created_by = request_payload['created_by'] || 'api_user'
      
      result = @user_manager.create_user(name, email, age, created_by: created_by)
      
      if result[:success]
        status 201  # Created
      else
        status 400  # Bad Request
      end
      
      result.to_json
      
    rescue JSON::ParserError
      status 400
      { success: false, error: "잘못된 JSON 형식입니다." }.to_json
    end
  end
  
  # PUT /users/:id - 사용자 정보 수정
  put '/users/:id' do
    begin
      id = params[:id].to_i
      request_payload = JSON.parse(request.body.read)
      
      result = @user_manager.update_user(
        id,
        name: request_payload['name'],
        email: request_payload['email'],
        age: request_payload['age'],
        updated_by: request_payload['updated_by'] || 'api_user'
      )
      
      if result[:success]
        status 200
      else
        status 404
      end
      
      result.to_json
      
    rescue JSON::ParserError
      status 400
      { success: false, error: "잘못된 JSON 형식입니다." }.to_json
    end
  end
  
  # DELETE /users/:id - 사용자 삭제
  delete '/users/:id' do
    id = params[:id].to_i
    result = @user_manager.delete_user(id)
    
    if result[:success]
      status 200
    else
      status 404
    end
    
    result.to_json
  end
  
  # GET /users/search/:name - 이름으로 사용자 검색
  get '/users/search/:name' do
    name = params[:name]
    result = @user_manager.search_users_by_name(name)
    status 200
    result.to_json
  end
  
  # GET /stats - 사용자 통계
  get '/stats' do
    result = @user_manager.get_stats
    status 200
    result.to_json
  end
  
  # GET / - API 정보
  get '/' do
    {
      success: true,
      message: "User Management API",
      version: "1.0.0",
      endpoints: {
        "GET /users" => "모든 사용자 조회",
        "GET /users/:id" => "특정 사용자 조회",
        "POST /users" => "새 사용자 생성",
        "PUT /users/:id" => "사용자 정보 수정",
        "DELETE /users/:id" => "사용자 삭제",
        "GET /users/search/:name" => "이름으로 사용자 검색",
        "GET /stats" => "사용자 통계"
      }
    }.to_json
  end
end

# 애플리케이션 실행
if __FILE__ == $0
  UserAPI.run! host: 'localhost', port: 4567
end