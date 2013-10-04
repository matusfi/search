Xhr.Options.spinner = 'spinner';
Xhr.Options.spinnerFx = 'fade';

"#search".onSubmit(function(event) {
  event.stop();
  this.send({
    onSuccess: function() {
      $('result').update(this.responseText);
    }
  });
});

".resource".onClick(function(event) {
    event.stop();
    $('result').slide();
    $('command').set('value', event.target.html().trim());
    $('result').load('/search', {method: 'get', 
                                params: {q: event.target.get('href')},
                                onComplete: function(request){
                                    $('result').slide();
                                }});
})