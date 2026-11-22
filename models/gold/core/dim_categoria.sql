select id_categoria, categoria, categoria_clave
from {{ ref('categorias') }}
union all
select -1, 'Sin categoría', 'sin categoria'
