module S3FormHelper
  def add_child_link(f, name, association, html_options = {}, options = {})
    html_options[:class] = "add_child edit #{html_options[:class]}"

    new_child_fields_template(f, association) unless options[:template] == false
    link_to(name, "javascript:void(0)", html_options.merge(:"data-association" => association))
  end

  def remove_child_link(f, name = t('remove'))
    sst do |output|
      output << f.input(:_destroy, :as => :hidden) if f.object.persisted?
      output << link_to(name, "javascript:void(0)", :class => "remove_child delete")
    end
  end

  def new_child_fields_template(form_builder, association, options = {})
    options[:object] ||= form_builder.object.class.reflect_on_association(association).klass.new
    options[:partial] ||= association.to_s.singularize + "_fields"
    options[:form_builder_local] ||= :f

    # Allow the fields_template id and the child_index to be overloaded for S3 uploads
    association_id = options[:id] || association

    content_for :new_child_fields_template do
      content_tag(:div, :id => "#{association_id}_fields_template", :style => "display: none") do
        form_builder.simple_fields_for(association, options[:object], :child_index => "new_#{association_id}") do |f|
          render(:partial => options[:partial], :locals => {options[:form_builder_local] => f})
        end
      end
    end
  end
end