$(document).ready(function(){
 $('.button').click(function(){
   //shows the form
   var form = $('#form');
   var selected_button = $(this);
   
   if(form.hasClass('visible'))
   {
     form.removeClass('visible');
     form.fadeOut(1300);
     
     selected_button.stop(true, false).animate({
      width: "44px",
      }, 700, function(){
        $(this).stop().fadeOut(300, function(){
          selected_button.fadeOut(300, function(){
             $('.button').fadeIn();
          });
        });
      });     
     
     $('.button').removeClass('selected-button');
   }
   else
   {
     form.addClass('visible');
     form.fadeIn();
     
     //hides all buttons
     $('.button').hide();

     selected_button = $(this);
     selected_button.show();
     selected_button.stop(true, false).animate({
      width: "200px",
      }, 1000 );
     selected_button.addClass('selected-button');
   }
 });
});