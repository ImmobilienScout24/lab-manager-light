beforeEach(function(){

  function replaceUmlaute(data) {
    "use strict";
    data = data.replace(/�/g, "ue");
    data = data.replace(/�/g, "Ue");
    data = data.replace(/�/g, "oe");
    data = data.replace(/�/g, "Oe");
    data = data.replace(/�/g, "ae");
    data = data.replace(/�/g, "Ae");
    data = data.replace(/�/g, "ss");

    return data;
  }

  this.addMatchers({

    toEqualAfterTrim: function(expected){
      var actual = this.actual || '';
        expected = expected.replace(/^\s+|\s+$/g, '');
        actual = actual.replace(/^\s+|\s+$/g, '');
      this.message = function(){
        return "Expected trimmed value '" + replaceUmlaute(actual) + "' to be '" + replaceUmlaute(expected)  + "'";
      };

      return actual === expected;
    },

    toEqualAfterNormalizedWhiteSpace: function(expected){
      "use strict";
      var actual = this.actual || '';
      actual  = actual.replace(/[\s][\s]*/g, " ").replace(/^[ \t]+|[ \t]+$/g,"");
      expected = expected.replace(/[\s][\s]*/g, " ").replace(/^[ \t]+|[ \t]+$/g,"");
      this.message = function(){
        return "Expected whitespace normalized value '"+ replaceUmlaute(actual) + "' to be '"+replaceUmlaute(expected) + "'";
      };
      return actual === expected;
    },

    toContainAfterNormalizedWhiteSpace: function(expected){
      "use strict";
      var actual = this.actual || '';
      actual  = actual.replace(/[\s][\s]*/g, " ").replace(/^[ \t]+|[ \t]+$/g,"");
      expected = expected.replace(/[\s][\s]*/g, " ").replace(/^[ \t]+|[ \t]+$/g,"");
      this.message = function(){
        return "Expected whitespace normalized value '"+ replaceUmlaute(actual) + "' to contain '"+replaceUmlaute(expected) + "'";
      };
      return actual.indexOf(expected) !== -1;

    }

  });
});