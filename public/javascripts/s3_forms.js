$('form a.add_child').live('click', function(e) {
    var assoc   = $(this).attr('data-association');
    var content = $('#' + assoc + '_fields_template').html();
    
    // Make a unique ID for the new child
    var regexp  = new RegExp('new_' + assoc, 'g');
    var new_id  = e.new_id || new Date().getTime();
    
    // Make the context correct by replacing new_<parents> with the generated ID
    // of each of the parent objects
    var context = ($(this).closest('.fields').find('input:first').attr('name') || '').replace(new RegExp('\[[a-z]+\]$'), '');

    // context will be something like this for a brand new form:
    // project[tasks_attributes][new_1255929127459][assignments_attributes][new_1255929128105]
    // or for an edit form:
    // project[tasks_attributes][0][assignments_attributes][1]
    if (context) {
      var parent_names = context.match(/[a-z_]+_attributes/g) || [];
      var parent_ids   = context.match(/(new_)?[0-9]+/g) || [];
      var assoc_prefix = '';

      for(var i = 0; i < parent_names.length; i++) {
        if(parent_ids[i]) {
          content = content.replace(
            new RegExp('(_' + parent_names[i] + ')_.+?_', 'g'),
            '$1_' + parent_ids[i] + '_');

          content = content.replace(
            new RegExp('(\\[' + parent_names[i] + '\\])\\[.+?\\]', 'g'),
            '$1[' + parent_ids[i] + ']');
        }
      }
      
      assoc = context.replace(/\]\[|\[|\]/g, '_') + assoc;
    }
    
    content = content.replace(regexp, "new_" + new_id);
    
    var field = $(content).appendTo('#' + assoc);
    
    $(this).closest("form").trigger({type: 'nested:fieldAdded', field: field});
    
    return false;
});

$('form a.remove_child').live('click', function() {
    var fields = $(this).closest('.fields');
    var destroy = fields.find('input[type=hidden][name$="[_destroy]"]')[0]
    if (destroy) {
        destroy.value = '1';
        fields.hide();
    } else {
        fields.remove();
    }
    
    $(this).closest("form").trigger('nested:fieldRemoved');
    
    return false;
});