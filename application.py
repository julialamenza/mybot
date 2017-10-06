from flask import Flask
import subprocess
cmd = 'python botjuly.py'
# Elastic Beanstalk initalization
application = Flask(__name__)
application.debug=True

subprocess.call(cmd, shell =True) 
#@application.route('/')
#def hello():
 #   return ''
