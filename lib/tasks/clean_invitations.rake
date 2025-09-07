namespace :invitations do
  desc "Clean up old broken invitation records"
  task cleanup: :environment do
    puts "Cleaning up old invitation records..."
    
    # Find all pending invitations
    old_invitations = Invitation.where(status: :pending)
    
    puts "Found #{old_invitations.count} pending invitations"
    
    if old_invitations.count > 0
      puts "Deleting old invitation records..."
      old_invitations.destroy_all
      puts "✅ Cleaned up old invitations successfully!"
    else
      puts "No old invitations to clean up."
    end
  end
end