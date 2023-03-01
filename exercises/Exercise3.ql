import javascript

from Function function
where
  function.getName() = "add" and
  function.getNumParameter() = 2 and
  function.getParameter(0).getName() = "req" and
  function.getParameter(1).getName() = "res"
select function
