import sys
print('Python path:', sys.path[0])

try:
    from database import get_db, init_db, User
    print('✅ Import successful!')
    print('get_db function:', get_db)
except ImportError as e:
    print('❌ Import failed:', e)
    
    # Try to import the module
    import database
    print('Database module:', database)
    print('Module file location:', database.__file__)
    print('\nModule contents:')
    for item in dir(database):
        if not item.startswith('_'):
            print(f'  - {item}')
