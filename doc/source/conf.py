# Always use the default theme for Readthedocs
RTD_NEW_THEME = True

extensions = []
templates_path = ['_templates']

source_suffix = '.rst'

master_doc = 'index'

project = u'The LMA Infrastructure Alerting plugin for Fuel'
copyright = u'2015, Mirantis Inc.'

version = '0.8'
release = '0.8.0'

exclude_patterns = []

pygments_style = 'sphinx'

html_theme = 'classic'
html_static_path = ['_static']

latex_documents = [
  ('index', 'LMAInfrastructureAlerting.tex', u'The LMA Infrastructure Alerting plugin for Fuel Documentation',
   u'Mirantis Inc.', 'manual'),
]
