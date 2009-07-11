module QuestionsHelper
  def status_link(id, status)
    text = status ? t('common.deactivate') : t('common.activate')
    link_to text, state_question_path(id, :active => status ? 0 : 1)
  end
end
