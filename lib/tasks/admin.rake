namespace :admin do
  desc "Promote a user to admin role"
  task :promote, [ :email ] => :environment do |task, args|
    email = args[:email]

    if email.blank?
      puts "Usage: rails admin:promote[user@example.com]"
      exit 1
    end

    user = User.find_by(email: email)

    if user.nil?
      puts "User with email '#{email}' not found"
      exit 1
    end

    if user.admin? || user.super_admin?
      puts "User '#{user.name}' (#{user.email}) is already an admin (#{user.role})"
    else
      user.update!(role: :admin)
      puts "User '#{user.name}' (#{user.email}) has been promoted to admin"
    end
  end

  desc "Promote a user to super admin role"
  task :super_promote, [ :email ] => :environment do |task, args|
    email = args[:email]

    if email.blank?
      puts "Usage: rails admin:super_promote[user@example.com]"
      exit 1
    end

    user = User.find_by(email: email)

    if user.nil?
      puts "User with email '#{email}' not found"
      exit 1
    end

    if user.super_admin?
      puts "User '#{user.name}' (#{user.email}) is already a super admin"
    else
      user.update!(role: :super_admin)
      puts "User '#{user.name}' (#{user.email}) has been promoted to super admin"
    end
  end

  desc "List all admin users"
  task list: :environment do
    admins = User.where(role: [ :admin, :super_admin ]).order(:role, :name)

    if admins.empty?
      puts "No admin users found"
    else
      puts "Admin Users:"
      puts "-" * 50
      admins.each do |user|
        puts "#{user.name.ljust(25)} #{user.email.ljust(30)} #{user.role.upcase}"
      end
    end
  end

  desc "Demote an admin user back to regular user"
  task :demote, [ :email ] => :environment do |task, args|
    email = args[:email]

    if email.blank?
      puts "Usage: rails admin:demote[user@example.com]"
      exit 1
    end

    user = User.find_by(email: email)

    if user.nil?
      puts "User with email '#{email}' not found"
      exit 1
    end

    if user.user?
      puts "User '#{user.name}' (#{user.email}) is already a regular user"
    else
      old_role = user.role
      user.update!(role: :user)
      puts "User '#{user.name}' (#{user.email}) has been demoted from #{old_role} to user"
    end
  end
end
