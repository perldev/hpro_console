    var HOST = "app-oracul-1.ceb.loc:8080";//"codeide.com" ;"test.codeide.com:8080";//
    var QS = (function(a) {
    if (a == "") return {};
    var b = {};
    for (var i = 0; i < a.length; ++i)
    {
        var p=a[i].split('=');
        if (p.length != 2) continue;
        b[p[0]] = decodeURIComponent(p[1].replace(/\+/g, " "));
    }
    return b;
})(window.location.search.substr(1).split('&')); 
function  my_alert(  Msg ){
//     
    if(!document.getElementById("my_alert")){
            
            var newdiv1 = $( "<div id='my_alert'><span id='msg' /><br/><div style='width:300px;align:center'><span class='btn' onclick='hide(\"my_alert\")' >Hide</span></div></div>" );
            $("body").append(newdiv1);            
            $("#my_alert").css("background","white")
                          .css("border","1px solid black")
                          .css("padding","25px")
                          .css("line-height","40px")
                          .css("position","absolute")
                          .css("top","20%").css("left","40%")
                          .css("z-index","1001")
                          .css("width","300px");            
                          
    }
    $("#msg").html(Msg); 
    $("#my_alert").show("fast");
    
    
}
function hide(id){
    $("#"+id).hide("fast");
}


