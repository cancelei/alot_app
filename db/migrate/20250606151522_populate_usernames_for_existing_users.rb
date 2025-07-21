class PopulateUsernamesForExistingUsers < ActiveRecord::Migration[8.0]
  def up
    # We need to use direct SQL to bypass the readonly attribute
    execute <<-SQL
      UPDATE users SET username = CASE
        WHEN email IS NOT NULL THEN
          LOWER(REGEXP_REPLACE(SPLIT_PART(email, '@', 1), '[^a-z0-9_]', '_', 'g'))
        ELSE
          CONCAT('user_', id)
      END
      WHERE username IS NULL OR username = '';
    SQL

    # Handle duplicates by adding a number suffix
    duplicates = execute(<<-SQL).to_a
      SELECT username, COUNT(*) as count
      FROM users
      GROUP BY username
      HAVING COUNT(*) > 1;
    SQL

    duplicates.each do |row|
      base_username = row['username']
      users = execute(<<-SQL).to_a
        SELECT id FROM users WHERE username = '#{base_username}' ORDER BY id;
      SQL

      # Skip the first one (keep original) and update the rest
      users[1..-1].each_with_index do |user, index|
        new_username = "#{base_username}#{index + 1}"
        execute("UPDATE users SET username = '#{new_username}' WHERE id = #{user['id']};")
      end
    end
  end

  def down
    # This migration is not reversible
  end
end
