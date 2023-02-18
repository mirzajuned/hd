// renumberFor - Takes fields within which type is to be renumbered
// typeArray - Takes type of fields to be renumbered Ex. "input", "select", etc.
// atIndex - Index position to be renumbered. Default : 1
// childRenumberFor - Renumber child of renumberFor : Optional
const renumberIndex = (renumberFor, typeArray, atIndex=1, childRenumberFor=[]) => {
  typeArray = Array.isArray(typeArray) ? typeArray : [typeArray]

  for (let i = 0; i < renumberFor.length; i++) {
    for(let type of typeArray){
      $(renumberFor[i]).find(type).each(function(index, element) {
        if (type === 'label') {
          let replaceForAt = 0
          let newFor =
            $(element).attr('for').replace(/[0-9]+/g, function (match) {
              replaceForAt++;
              return (replaceForAt === atIndex) ? i : match;
            });
          $(element).attr('for', newFor)
        } else {
          let replaceNameAt = replaceIdAt = 0;
          let newName =
            element.name.replace(/[0-9]+/g, function (match) {
              replaceNameAt++;
              return (replaceNameAt === atIndex) ? i : match;
            });
          $(element).attr("name", newName)
          let newId =
            element.id.replace(/[0-9]+/g, function (match) {
              replaceIdAt++;
              return (replaceIdAt === atIndex) ? i : match;
            });
          $(element).attr("id", newId)
        }
      })
    }

    if(childRenumberFor.length > 0){
      newRenumberFor = $(renumberFor[i]).find(childRenumberFor[0])
      newChildRenumberFor = childRenumberFor.splice(1, -1)
      newAtIndex = atIndex + 1
      renumberIndex(newRenumberFor, typeArray, newAtIndex, newChildRenumberFor)
    }
  }
};

// Code By : HUZAIFA SAIFUDDIN