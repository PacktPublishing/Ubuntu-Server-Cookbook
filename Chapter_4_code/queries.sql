# search for virtual domain
SELECT 1 FROM virtual_domains WHERE name='%s'

# search for user account 
SELECT 1 FROM virtual_users WHERE email='%s'

# search for alias
SELECT destination FROM virtual_aliases WHERE source='%s'