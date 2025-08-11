# Capa Base de Datos
Genera un único archivo SQL compatible con Azure SQL, no interesan los demás motores de Base de Datos que cumpla los siguientes criterios

Antes de un CREATE SCHEMA o CREATE TRIGGER, pon una sentencia GO para separar los bloques y no de error

Al inicio del script, haz un DROP de todos los objetos si es que existen

## Consideraciones para generar el script
Las tablas son para Azure SQL

Todas las fechas y horas deben considerarse en la zona horaria -5 de Lima, Perú

Todos los objetos son en minúsculas separados por el caracter "_" y además pertenecen a un esquema

Todos los campos de las tablas son obligatorios, a no ser que se indique lo contrario

Si indico un FOREIGN KEY, toma el tipo de dato de la tabla padre

### Consideraciones para el Primary Key
Los Primary Key (PK) deben tener el formato "pk_{nemonico}" donde:
{nemonico} es el nemónico de la tabla

### Consideraciones para el Foreign Key
Los Foreign Key (FK) deben tener el formato "fk_{nemonico_tabla_padre}_{nemonico_tabla_hija}" donde:
{nemonico_tabla_padre} es el nemónico de la tabla padre
{nemonico_tabla_hija} es el nemónico de la tabla hija, la que recibe el FK

### Consideraciones para las Tablas de Trazabilidad
Si la tabla tiene la indicación "Trazabilidad = Sí"

a) Generar una tabla adicional, en el mismo esquema de la tabla, con el formato "{tabla}_atl" donde:
{tabla} es el nombre de la tabla y sus campos son:
* atl_written_at    DATETIMEOFFSET(2) : es la fecha y hora en que se dispara el trigger
  * atl_app_name      NVARCHAR(128)     : es la función APP_NAME() de Azure SQL
  * atl_host_name     NVARCHAR(128)     : es la función HOST_NAME() de Azure SQL
  * atl_user          SYSNAME           : es la función CURRENT_USER de Azure SQL
  * atl_action        VARCHAR(3)        : "INS" si es INSERT, "UPD" si es UPDATE, "DEL" si es DELETE
  * y los demás campos de la tabla original. Los campo "atl_" son obligatorios, pero los demás campos son opcionales y sin PRIMARY KEY ni FOREIGN KEY

b) Crear un trigger, en el mismo esquema de la tabla, del tipo "AFTER INSERT, UPDATE, DELETE" con el formato "trg_iud_{tabla}" donde:
{tabla} es el nombre de la tabla
Este trigger se encarga de llevar los datos de la tabla original a la tabla del tipo "atl" indicando especialmente si fue un INS, UPD o DEL

### Campos de auditoría de todas las tablas
Se deben agregar estos campos obligatorios al final de todas las tablas:
* author_id VARCHAR(16)
* written_at DATETIMEOFFSET(2)

Si se va a poblar alguna tabla en forma inicial se debe poner como author_id a "SYSTEM"



## Esquema de Tablas de Parámetros
Nombre: bank_params

### Tabla de Estados de un Crédito
Nombre: credit_states

Trazabilidad: No

Nemónico: credsta

Campos:
* credit_state_id               VARCHAR(3) PRIMARY KEY
* credit_state_description      VARCHAR(32)

Valores iniciales:
PRO, EN PROCESO
APR, APROBADO
DES, DESAPROBADO

### Tabla de Tipos de Cliente
Nombre: client_types

Trazabilidad: No

Nemónico: clityp

Campos:
* client_type_id               VARCHAR(3) PRIMARY KEY
* client_type_description      VARCHAR(32)

Valores iniciales:
* MIC, MICRO EMPRESA
* PEQ, PEQUEÑA EMPRESA
* MED, MEDIANA EMPRESA
* GRA, GRAN EMPRESA

### Tabla de Categoría de Riesgo de Cliente
Nombre: risk_categories

Trazabilidad: No

Nemónico: rskcat

Campos:
* risk_category_id          VARCHAR(2) PRIMARY KEY
* risk_category_description VARCHAR(32)

Valores iniciales:
* NO, NORMAL
* PP, PROBLEMA POTENCIAL
* DE, DEFICIENTE
* DU, DUDOSO
* PE, PÉRDIDA

## Esquema de Tablas de Negocio
bank

### Tabla de Clientes
Nombre: client

Trazabilidad: Sí

Nemónico: cli

Campos:
* client_id VARCHAR(16) PRIMARY KEY
* client_name VARCHAR(256)
* client_type_id FOREIGN KEY con client_types
* risk_category_id FOREIGN KEY con risk_categories
* credit_line_authorized_amount NUMERIC(15, 2)
* credit_line_used_amount NUMERIC(15, 2)


### Tabla de Solicitudes de Crédito 
Nombre: credit_orders

Trazabilidad: Sí

Nemónico: creord

Campos:
* credit_order_id INT IDENTITY PRIMARY KEY
* client_id FOREIGN KEY con client
* amount NUMERIC(15, 2)
* interest_rate NUMERIC(5, 2)
* due_date DATE
* client_type_id FOREIGN KEY con client_types, es la foto de cuando se INSERTa el registro, según client
* risk_category_id FOREIGN KEY con risk_categories, es la foto de cuando se INSERTa el registro, según client
* credit_line_authorized_amount NUMERIC(15, 2), es la foto de cuando se INSERTa el registro, según client
* credit_line_used_amount NUMERIC(15, 2), es la foto de cuando se INSERTa el registro, según client
* credit_state_id FOREIGN KEY con credit_states

## Data de Prueba
Al final genérame data de prueba para la tabla client y credit_orders con las siguientes características

### Tabla de Clientes
Genera 100 clientes
* client_id : con la forma de RUC de empresas peruanas, parecidas, no iguales para evitar problemas legales. Que no existan duplicados en toda la tabla.
* client_name :
  * Con nombre de empresas peruanas, ficticias, de los rubros (transporte, minería, aviación, educación, librerías, supermercados, abarrotes y otros cinco que sean comunes en Perú).
  * Los tipos de empresa pueden ser (SA, SAC, EIRL y otros dos comunes en Perú)
  * Es posible que los nombres sean duplicados
  * Puedes usar nombres de:
    * Todos los santos peruanos
    * 10 provincias y 20 distritos del Perú
    * 15 playas del Perú
    * 10 minerales que exporte el Perú
    * 15 peces más pescados en Perú
    * Todos los nombres de Papas de la Edad Media
    * 20 nombres de países y capitales de África y Oceanía
    * Puedes combinarlos en aras de tratar de no repetir los nombres como "Empresa Oro y El Cairo SA"
* client_type_id: el 5% GRA, el 25% MED, el 40% PEQ y el 30% MIC
* risk_category_id :
  * en caso de GRA (80% NO, 10% PP, 05% DE, 03% DU, 02% PE)
  * en caso de MED (70% NO, 15% PP, 10% DE, 01% DU, 04% PE)
  * en caso de PEQ (50% NO, 30% PP, 05% DE, 05% DU, 10% PE)
  * en caso de MIC (20% NO, 40% PP, 20% DE, 10% DU, 10% PE) 
* credit_line_authorized_amount : montos que acaben en 000.00 (es decir, centenas, decenas y unidades en cero, así como la parte decimal también en cero) y variando aleatoriamente entre: 
  * en caso de GRA (entre 12,000,000 y 50,000,000)
  * en caso de MED (entre 9,000,000 y 12,000,000)
  * en caso de PEQ (entre 800,000 y 9,000,000)
  * en caso de MIC (entre 10,000 y 800,000)
* credit_line_used_amount : montos que esten entre 0.00 (valor absoluto) y 5% más del credit_line_authorized_amount para ese cliente

### Tabla de Solicitudes de Crédito
Genera por cada cliente la siguiente cantidad de créditos:
  * en caso de GRA (entre 0 y 100)
  * en caso de MED (entre 0 y 50)
  * en caso de PEQ (entre 0 y 10)
  * en caso de MIC (entre 0 y 3)
* credit_order_id : no lo tomes en cuenta, pues es un IDENTITY
* client_id : el client_id de la tabla cliente
* credit_state_id: 
    * en caso de GRA (90% Aprobados, 02% Desaprobados, 08% En Proceso)
    * en caso de MED (80% Aprobados, 10% Desaprobados, 10% En Proceso)
    * en caso de PEQ (50% Aprobados, 20% Desaprobados, 30% En Proceso)
    * en caso de MIC (50% Aprobados, 30% Desaprobados, 20% En Proceso)
* * amount :
  * acá quiero simular que el cliente pide créditos a lo largo del tiempo, el banco le asigna una línea de crédito (credit_line_authorized_amount)
  * obviamente el cliente empieza con un credit_line_used_amount de CERO pero a medida que el banco le aprueba créditos este monto debe aumentar. No tomar en cuenta los desaprobados o en proceso.
  * es decir debe simular que el cliente está pidiendo créditos y estos han sido aprobados de modo que va consumiendo la línea del cliente hasta llegar al monto indicado en la tabla cliente
* interest_rate : 
    * en caso de GRA (entre 0.5 y 3)
    * en caso de MED (entre 3 y 7)
    * en caso de PEQ (entre 5 y 10)
    * en caso de MIC (entre 10 y 30)
* written_at : es la fecha en que pidió el crédito, desde dos años atrás hasta un mes atrás. ten en cuenta el orden de las fechas y los montos para que parezca que el cliente va pidiendo créditos en forma ordenada y va aumentando el monto usado en esta tabla
* due_date : entre hoy y dos años atrás, solo considera de lunes a viernes y no tomes en cuenta los feriados peruanos
* client_type_id : el client_type_id de la tabla cliente 
* risk_category_id : el risk_category_id de la tabla cliente
* credit_line_authorized_amount : el credit_line_authorized_amount de la tabla cliente 
* credit_line_used_amount : es el monto usado de la línea, es decir según los créditos aprobados del cliente, empieza de cero y termina igual al credit_line_used_amount de la tabla cliente 
 
# Archivos esperados
## drop-objects.sql
Con las sentencias para eliminar todos los objetos previos a la ejecución de este script. Validando previamente si existen o no

## create-objects.sql
Con las sentencias para la creación ordenada y lógica de schemas, tablas, triggers

## insert-params.sql
Con las sentencias para poblar las tablas del esquema bank_params

## drop-test-data.sql
Con las sentencias para eliminar ordenada y lógicamente la data de las tablas del esquema bank

## insert-clients-test-data.sql
Con las sentencias para poblar la data de clients según las reglas indicadas

## insert-credit-orders-test-data.sql
Con las sentencias para poblar la data de clients según las reglas indicadas