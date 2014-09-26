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

.. _`Why aren't you using git-flow`: http://jeffkreeftmeijer.com/2010/why-arent-you-using-git-flow/
.. _`nvie's gitflow plugin`: https://github.com/nvie/gitflow
