$env.FOO = 'BAR'


{"BAR":"$'(echo BAZ)'","BOOLEAN_VAR":true,"LIST_VAR":["elem1",2],"NUMERIC_VAR":4} | load-env
