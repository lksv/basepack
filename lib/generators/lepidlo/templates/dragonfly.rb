require 'dragonfly/rails/images'

Dragonfly[:images].configure do |c|
    c.protect_from_dos_attacks = true
    c.secret = 'b6c2fv78b90bukc8d32a13274af4' # random secret

end

