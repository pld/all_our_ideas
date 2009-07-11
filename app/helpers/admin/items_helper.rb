module Admin::ItemsHelper
  def question_add_to_select
    select_tag 'question', options_for_select(@questions.transpose[0,2].reverse.transpose, @question_id)
  end
end
