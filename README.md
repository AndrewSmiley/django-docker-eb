django-docker-eb
================

Ok everyone, here it is, the basic configuration to make Django play nicely with Docker on AWS Elastic Beanstalk. All the source code for this project can be found at https://github.com/AndrewSmiley/django-docker-eb. 

I'm not writing a Docker how-to here. If you're totally lost, consult the Docker docs <a href="https://docs.docker.com/">here</a> or <a href="https://github.com/wsargent/docker-cheat-sheet">here</a>. 

In addition, I'm not writing a Django/Gunicorn/Nginx/Etc tutorial here. There's a plethora of them out there, if you want to learn, great! Use them! I did too! That being said, I'm making the assumption that you have some familiarity with all of the required tools... So let's begin, shall we?

<h3>Required software</h3>
<ul>
<li>Django </li>
<li>Gunicorn </li>
<li>Supervisor </li>
</ul>

<h3>Required configs</h3>
<ul>
<li>supervisord.conf </li>
<li>Dockerfile </li>
<li>Dockerrun.aws.json </li>
<li>Other assorted Django configs for your Django Project </li>
</ul>

So basically, create your Django project locally. Make sure it runs locally. I would suggest doing this on a *nix system using terminal and 

    python manage.py runserver. 

Since we know our project works, let's go ahead and create the dependencies file, requirements.txt. from the base directory of your project, run 

    pip freeze > requirements.txt
    
In addition, you'll want to add gunicorn to your requirements.txt.

Now, from the either the terminal or your favorite IDE, add a Dockerfile. Mine looked like this:

    FROM ubuntu
    MAINTAINER Andrew Smiley
    # Update packages
    RUN apt-get update -y
    
    # Install Python Setuptools and some other fancy tools for working we this container if we choose to attach to it
    RUN apt-get install -y tar git curl nano wget dialog net-tools build-essential
    RUN apt-get install -y python python-dev python-distribute python-pip supervisor
    
    # copy the contents of this directory over to the container at location /src
    ADD . /src
    
    
    # Add and install Python modules
    #we shouldn't have to do this twice but that's how the folks over at amazon suggested.
    # we'd probably be fine with just ADD . /src
    ADD requirements.txt /src/requirements.txt
    RUN cd /src && pip install -r /src/requirements.txt
    
    ###############################################################################################################################################################
    # This is the important part. The port we are exposing needs to match the port we are binding GUNICORN too. See the supervisord.conf file for the proper conf #
    ###############################################################################################################################################################
    EXPOSE  8002
    #set the working directorly
    WORKDIR /src
    
    #basically this is the command to execute when we run the contaner. This is the default for sudo     docker run for this image
    CMD supervisord -c /src/supervisord.conf

Now that we have a Docker file, we'll want to add a Dockerrun.aws.json file. Now, according to the AWS EB+Docker docs, if you deploy a project with a Dockerfile you do not have to create a Dockerrun.aws.json file. <i>HOWEVER,</i> like many of the other wonderful services provided by Amazon (I'm a little jaded as you can tell), the documentation does not tell the story. My experience was that you DO in face need both the Dockerfile and Dockerrun.aws.json to deploy to EB in this way. Anyway, your Dockerrun.aws.json can be as simple or complex as you like. Mine looked like 

    {
      "AWSEBDockerrunVersion": "1",
      "Volumes": [
        {
          "ContainerDirectory": "/var/app",
          "HostDirectory": "/var/app"
        }
      ],
      "Logging": "/var/eb_log"
    }

So now that we've added those EB requirements, we can add the last piece in, which is the supervisord.conf file. There's several ways of getting one/creating one. Personally if I recall directly, I generated mine using the Supervisor install a while back. Really, there is not a huge amount you need to change just to get it running. Basically, there's two directives that we need to focus on in supervisord.conf. First, modify your supervisord directive to resemble this. The important thing ehre is the nodaemon setting needs to be set to true.

    [supervisord]
    logfile=/tmp/supervisord.log ; (main log file;default $CWD/supervisord.log)
    logfile_maxbytes=50MB        ; (max main logfile bytes b4 rotation;default 50MB)
    logfile_backups=10           ; (num of main logfile rotation backups;default 10)
    loglevel=info                ; (log level;default info; others: debug,warn,trace)
    pidfile=/tmp/supervisord.pid ; (supervisord pidfile;default supervisord.pid)
    nodaemon=true                ; (start in foreground if true;default false)
    minfds=1024                  ; (min. avail startup file descriptors;default 1024)
    minprocs=200                 ; (min. avail process descriptors;default 200)
    ;umask=022                   ; (process file creation umask;default 022)
    ;user=chrism                 ; (default is current user, required if root)
    ;identifier=supervisor       ; (supervisord identifier, default is 'supervisor')
    ;directory=/tmp              ; (default is not to cd during start)
    ;nocleanup=true              ; (don't clean up tempfiles at start;default false)
    ;childlogdir=/tmp            ; ('AUTO' child log dir, default $TEMP)
    ;environment=KEY="value"     ; (key value pairs to add to environment)
    ;strip_ansi=false            ; (strip ansi escape codes in logs; def. false)


Now, add in this program directive to run Gunicorn with Supervisor

    ;The program to execute gunicorn
    [program:gunicorn]
    enviroment=PYTHONPATH=/usr/local/bin:/bin/
    user=root
    command=gunicorn django_eb.wsgi:application --bind=0.0.0.0:8002 ;
    directory=/src/


Once we've completed all of these steps, we're ready to zip our project and upload to Elastic Beanstalk.  
Zip all the contents of your base project directory and deploy to Elastic beanstalk

Alternatively, try this simple sequence:

    git clone REPO_URL/django-docker-eb.git
    cd django-docker-eb
    eb init -p Docker
    eb create dev-env

Then visit the url you are given when the final step completes.

The above assumes that you have set a user with the appropriate credentials in your 
environment.  If you have not done so, you'll be asked by eb init for credentials.

The easy approach is with IAM. Create a user. Name the user dj-docker-eb-test-user
and confer admin privilege. Pass the new credentials to eb init.

