class UseCasesController < ApplicationController
  # No authentication required for use case pages

  def birthdays
    @use_case = 'birthdays'
    @page_title = t('use_cases.birthdays.title')
    @page_description = t('use_cases.birthdays.meta_description')
  end

  def weddings
    @use_case = 'weddings'
    @page_title = t('use_cases.weddings.title')
    @page_description = t('use_cases.weddings.meta_description')
  end

  def holidays
    @use_case = 'holidays'
    @page_title = t('use_cases.holidays.title')
    @page_description = t('use_cases.holidays.meta_description')
  end

  def couples
    @use_case = 'couples'
    @page_title = t('use_cases.couples.title')
    @page_description = t('use_cases.couples.meta_description')
  end

  def families
    @use_case = 'families'
    @page_title = t('use_cases.families.title')
    @page_description = t('use_cases.families.meta_description')
  end
end