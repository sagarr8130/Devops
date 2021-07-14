from flask_wtf import FlaskForm
from wtforms import PasswordField, SubmitField, TextField


class SignUpForm(FlaskForm):
    password = PasswordField('Refresh Token')
    submit = SubmitField('Submit')


class EnvironmentForm(FlaskForm):
    stack = TextField('Stack')
    release_version = TextField('Release Version')
    environment = TextField('Environment')
    service = TextField('Service')
    proceed = SubmitField('Proceed')


class RightScriptForm(FlaskForm):
    rs_name = TextField('Rightscript Name')
    confirm = SubmitField('Confirm')
