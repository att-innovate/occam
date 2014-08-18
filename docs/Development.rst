=================
Occam development
=================

Repository best practices
=========================

This project follows the conventions described in Jeff Kreeftmeijer's seminal 
blog post `Why aren't you using git-flow`_ and implemented in 
`nvie's gitflow plugin`_. When deploying a new environment, it's recommended
that a feature branch be created and changes tested there first. The rest of
this document assumes this has been done.

.. code:: bash

    % git flow feature start my-new-environment
