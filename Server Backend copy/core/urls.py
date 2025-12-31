from django.contrib import admin
from django.urls import path
from . import views

urlpatterns = [
    # The Visual Dashboard
    path('', views.home, name='home'),
    
    # The iPhone Data Feed
    path('intel', views.intel_api, name='intel'),
]
