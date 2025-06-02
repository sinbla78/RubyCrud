require 'pg'
require 'dotenv/load'

class Database
  @@connection = nil
  
  def self.connect
    return @@connection if @@connection && !@@connection.finished?
    
    begin
      @@connection = PG.connect(
        host: ENV['DB_HOST'] || 'localhost',
        port: ENV['DB_PORT'] || 5432,
        dbname: ENV['DB_NAME'] || 'ruby_crud_auth',
        user: ENV['DB_USER'] || 'postgres',
        password: ENV['DB_PASSWORD']
      )
      
      puts "✅ PostgreSQL 데이터베이스에 성공적으로 연결되었습니다."
      @@connection
    rescue PG::Error => e
      puts "❌ 데이터베이스 연결 실패: #{e.message}"
      puts "💡 PostgreSQL이 실행 중인지, .env 파일 설정이 올바른지 확인해주세요."
      exit(1)
    end
  end
  
  def self.connection
    @@connection || connect
  end
  
  def self.disconnect
    if @@connection && !@@connection.finished?
      @@connection.close
      @@connection = nil
      puts "🔌 데이터베이스 연결이 해제되었습니다."
    end
  end
  
  def self.execute(query, params = [])
    connection.exec_params(query, params)
  rescue PG::Error => e
    puts "❌ SQL 실행 오류: #{e.message}"
    puts "쿼리: #{query}"
    nil
  end
  
  def self.test_connection
    result = execute("SELECT version();")
    if result
      puts "🎯 데이터베이스 테스트 성공: #{result[0]['version']}"
      true
    else
      false
    end
  end
end