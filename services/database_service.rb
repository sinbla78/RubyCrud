require_relative '../config/database'

class DatabaseService
  # 데이터베이스 초기화 및 테이블 생성
  def self.initialize_database
    puts "🔧 데이터베이스 초기화를 시작합니다..."
    
    # auth_users 테이블 생성
    create_auth_users_table
    
    # users 테이블 생성
    create_users_table
    
    # 인덱스 생성
    create_indexes
    
    puts "✅ 데이터베이스 초기화가 완료되었습니다!"
  end
  
  # 데이터베이스 테이블 존재 확인
  def self.tables_exist?
    auth_users_exists = table_exists?('auth_users')
    users_exists = table_exists?('users')
    
    auth_users_exists && users_exists
  end
  
  # 특정 테이블 존재 확인
  def self.table_exists?(table_name)
    result = Database.execute(
      "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = $1)",
      [table_name]
    )
    
    result && result[0]['exists'] == 't'
  end
  
  # 데이터베이스 상태 체크
  def self.health_check
    puts "🏥 데이터베이스 상태 체크를 시작합니다..."
    
    # 연결 테스트
    unless Database.test_connection
      puts "❌ 데이터베이스 연결 실패"
      return false
    end
    
    # 테이블 존재 확인
    unless tables_exist?
      puts "⚠️ 필요한 테이블이 존재하지 않습니다. 초기화를 실행합니다."
      initialize_database
    end
    
    # 데이터 통계
    show_database_stats
    
    puts "✅ 데이터베이스 상태가 정상입니다!"
    true
  end
  
  # 데이터베이스 통계 정보
  def self.show_database_stats
    puts "\n📊 데이터베이스 통계:"
    puts "-" * 40
    
    # auth_users 테이블 통계
    auth_result = Database.execute("SELECT COUNT(*) as count FROM auth_users")
    auth_count = auth_result ? auth_result[0]['count'].to_i : 0
    puts "가입된 계정 수: #{auth_count}"
    
    # users 테이블 통계
    users_result = Database.execute("SELECT COUNT(*) as count FROM users")
    users_count = users_result ? users_result[0]['count'].to_i : 0
    puts "총 관리 사용자 수: #{users_count}"
    
    # 평균 나이
    if users_count > 0
      avg_result = Database.execute("SELECT AVG(age) as avg_age FROM users")
      avg_age = avg_result ? avg_result[0]['avg_age'].to_f : 0
      puts "평균 나이: #{'%.1f' % avg_age}세"
    end
    
    puts "-" * 40
  end
  
  # 데이터베이스 백업 (간단한 CSV 형태)
  def self.backup_to_csv
    puts "💾 데이터베이스 백업을 시작합니다..."
    
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    backup_dir = "backups"
    
    # 백업 디렉토리 생성
    Dir.mkdir(backup_dir) unless Dir.exist?(backup_dir)
    
    # auth_users 백업
    backup_auth_users(backup_dir, timestamp)
    
    # users 백업
    backup_users(backup_dir, timestamp)
    
    puts "✅ 백업이 완료되었습니다! (#{backup_dir}/ 폴더 확인)"
  end
  
  # 데이터베이스 정리
  def self.cleanup_old_data(days_old = 30)
    puts "🧹 #{days_old}일 이전 데이터를 정리합니다..."
    
    cutoff_date = Date.today - days_old
    
    result = Database.execute(
      "DELETE FROM users WHERE created_at < $1",
      [cutoff_date]
    )
    
    deleted_count = result ? result.cmd_tuples : 0
    puts "🗑️ #{deleted_count}개의 오래된 사용자 데이터가 삭제되었습니다."
  end
  
  # 데이터베이스 최적화
  def self.optimize_database
    puts "⚡ 데이터베이스 최적화를 시작합니다..."
    
    # 통계 정보 업데이트
    Database.execute("ANALYZE auth_users")
    Database.execute("ANALYZE users")
    
    # 인덱스 재구성 (필요시)
    Database.execute("REINDEX TABLE auth_users")
    Database.execute("REINDEX TABLE users")
    
    puts "✅ 데이터베이스 최적화가 완료되었습니다!"
  end
  
  # 개발용 샘플 데이터 생성
  def self.seed_sample_data
    puts "🌱 샘플 데이터를 생성합니다..."
    
    # 샘플 관리자 계정 생성 (개발용)
    require_relative '../utils/password_helper'
    
    sample_password = PasswordHelper.hash_password("Admin123!")
    
    Database.execute(
      "INSERT INTO auth_users (username, email, password_hash) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING",
      ["admin", "admin@example.com", sample_password]
    )
    
    # 관리자 ID 가져오기
    admin_result = Database.execute("SELECT id FROM auth_users WHERE username = 'admin'")
    return unless admin_result && admin_result.ntuples > 0
    
    admin_id = admin_result[0]['id'].to_i
    
    # 샘플 사용자들 생성
    sample_users = [
      ["홍길동", "hong@example.com", 25],
      ["김영희", "kim@example.com", 30],
      ["이철수", "lee@example.com", 28],
      ["박민수", "park@example.com", 35],
      ["정수연", "jung@example.com", 27]
    ]
    
    sample_users.each do |name, email, age|
      Database.execute(
        "INSERT INTO users (name, email, age, created_by) VALUES ($1, $2, $3, $4) ON CONFLICT DO NOTHING",
        [name, email, age, admin_id]
      )
    end
    
    puts "✅ 샘플 데이터 생성 완료!"
    puts "💡 샘플 계정 - 사용자명: admin, 비밀번호: Admin123!"
  end
  
  private
  
  # auth_users 테이블 생성
  def self.create_auth_users_table
    sql = <<~SQL
      CREATE TABLE IF NOT EXISTS auth_users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    SQL
    
    Database.execute(sql)
    puts "📝 auth_users 테이블이 생성되었습니다."
  end
  
  # users 테이블 생성
  def self.create_users_table
    sql = <<~SQL
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100) NOT NULL,
        age INTEGER NOT NULL CHECK (age > 0 AND age < 150),
        created_by INTEGER REFERENCES auth_users(id) ON DELETE CASCADE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    SQL
    
    Database.execute(sql)
    puts "📝 users 테이블이 생성되었습니다."
  end
  
  # 인덱스 생성
  def self.create_indexes
    indexes = [
      "CREATE INDEX IF NOT EXISTS idx_auth_users_username ON auth_users(username)",
      "CREATE INDEX IF NOT EXISTS idx_auth_users_email ON auth_users(email)",
      "CREATE INDEX IF NOT EXISTS idx_users_created_by ON users(created_by)",
      "CREATE INDEX IF NOT EXISTS idx_users_name ON users(name)",
      "CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)"
    ]
    
    indexes.each do |index_sql|
      Database.execute(index_sql)
    end
    
    puts "📇 인덱스가 생성되었습니다."
  end
  
  # auth_users 백업
  def self.backup_auth_users(backup_dir, timestamp)
    filename = "#{backup_dir}/auth_users_#{timestamp}.csv"
    
    result = Database.execute("SELECT id, username, email, created_at FROM auth_users ORDER BY id")
    return unless result && result.ntuples > 0
    
    File.open(filename, 'w') do |file|
      file.puts "id,username,email,created_at"
      result.each do |row|
        file.puts "#{row['id']},#{row['username']},#{row['email']},#{row['created_at']}"
      end
    end
    
    puts "💾 auth_users 백업 완료: #{filename}"
  end
  
  # users 백업
  def self.backup_users(backup_dir, timestamp)
    filename = "#{backup_dir}/users_#{timestamp}.csv"
    
    result = Database.execute("SELECT id, name, email, age, created_by, created_at FROM users ORDER BY id")
    return unless result && result.ntuples > 0
    
    File.open(filename, 'w') do |file|
      file.puts "id,name,email,age,created_by,created_at"
      result.each do |row|
        file.puts "#{row['id']},#{row['name']},#{row['email']},#{row['age']},#{row['created_by']},#{row['created_at']}"
      end
    end
    
    puts "💾 users 백업 완료: #{filename}"
  end
end