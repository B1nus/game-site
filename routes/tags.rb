# frozen_string_literal: true

get('/admin/tags/new') do
  erb(:'tags/new', locals: { purposes: @database.all_of('tag_purpose') })
end

get('/admin/tags/:id/edit') do
  erb(:'tags/edit', locals: {
        tag: @database.select('tag', 'id', params_id),
        tag_purposes: @database.all_of('tag_purpose')
      })
end

get('/admin/tags/:id') do
  erb(:'tags/show', locals: {
        tag: @database.select('tag', 'id', params_id)
      })
end

get('/admin/tags') do
  erb(:'tags/index', locals: {
        tags: @database.all_of('tag'),
        tag_purposes: @database.all_of('tag_purpose')
      })
end

# Add a new tag
#
# @param tag_name [String]
# @param tag_purpose_id [Integer]
post('/admin/tags') do
  flash[:notice] = @database.add_tag(params[:name], params[:purpose_id].to_i)
  redirect '/games'
end

# Update a tag
#
# @param [Integer] id, the id of the tag
# @param [String] tag_name, the new name of the tag
# @param [Integer] tag_purpose_id, the new tag purpose id
#
# @see Model#database_edit_tag
post('/admin/tags/:id/update') do
  redirect "/admin/tags/#{params_id}/edit" if flash[:notice] = @database.update_tag(
    params_id,
    params[:name],
    params[:purpose_id].to_i
  )

  redirect '/games'
end

# Remove a tag
#
# @param [Integer] id, The id for the tag
post('/admin/tags/:id/delete') do
  flash[:notice] = @database.delete_tag(params_id)

  redirect '/games'
end
