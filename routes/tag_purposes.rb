# frozen_string_literal: true

# Create a new tag purpose
#
post('/admin/tag-purposes') do
  flash[:notice] = @database.add_tag_purpose(params[:purpose])
  redirect '/games'
end
