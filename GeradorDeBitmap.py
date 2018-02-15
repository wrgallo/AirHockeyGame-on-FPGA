from __future__ import print_function
try:
    import scipy.misc as sm
    from PIL import Image
    try:
        from pylab import *
    except:
        print("\nInstale a biblioteca matplotlib, caso deseje visualizar o resultado final.\n")
        None
except:
    print ("Instale as bibliotecas SciPy e PIL !!")
    raw_input("")

def RGBtoHEX( rgb ):
    return 65536*rgb[0] + 256*rgb[1] + rgb[2]
    

def Aproximacao( rgb1, rgb2, tol=1e-05 ):
    aproximado = True

    a = RGBtoHEX( list( rgb1 ) )
    b = RGBtoHEX( list( rgb2 ) )
    
    if(  (abs( a-b )/( a*1.0 )) > tol ): aproximado = False

    return aproximado

def CorParecida( img, i, j , tol = 0.02 ):
    cor = list( img[i][j] )
    parecida = True

    referenciais  = [ list(     img[i-1][ j ] ) ,
                      list(     img[i-1][j-1] ) ,
                      list(     img[ i ][j-1] ) 
                      ]
    try:
        referenciais.append( list( img[i-1][j+1] ) )
    except:
        None
    
    testes = [ Aproximacao( referenciais[k], list( img[i][j] ), tol ) for k in xrange( len(referenciais) ) ]
    
    for k in xrange( len(testes) ):
        if( not testes[k] ):
            parecida = False
            break
        
    if( parecida ):
        return list( img[ i ][j-1] ) 
    return cor

def teste( new_img ):
    L = len( new_img )
    C = len( new_img[0] )
    iteracao = 1
    for i in xrange( L ):
        print('\r'*3,end='N%'.replace('N','% 1.f' % (100*iteracao/float(L)) ));iteracao += 1
        for j in xrange( C ):
            hexa = str( hex( RGBtoHEX( new_img[i][j] ) ) )[:8].replace("0x","#")
            if( hexa[-1] == 'L' ):
                hexa = hexa.replace( 'L', '' )
                while( len(hexa)<7 ): hexa = ( "#0?".replace( "?", hexa[1:] ) )
            plot( j , L-1-i , hexa, marker='s', ms=6 )
    return show()

arquivo = raw_input("Nome da Imagem (seguido de extensao): ")
img     = sm.imread( arquivo )

L = len( img    )
C = len( img[0] )

try:
    imshow( array(Image.open( arquivo )) )
    show()
except:
    None

new_img = [0]*L
for i in xrange( L ): new_img[i] = [0]*C

for ponto in range( len(arquivo)-2, 1, -1 ):
    if( arquivo[ponto] == '.' ): break
arq_saida = arquivo.replace( arquivo[ ponto : ], ".txt" )
arq_saida = open( arq_saida, 'w' )

bitmap = False
RGB_1D = False
RGB_3D = False
poucas_cores = False

if(    len(img.shape)==2 ):
    bitmap = True
    for i in xrange( L ):
        if( img[i][ img[ i ].argmax() ] > 1 ):
            RGB_1D = True
            bitmap = False
            break
elif(  len(img.shape)==3 ):
    RGB_3D = True
    #if( raw_input("\nCaso deseje uma matriz de poucas cores,\npressione 1: ")=='1' ): poucas_cores = True
    poucas_cores = True
else: print ("Formato Incompativel de cores.")

iteracao = 1
if( bitmap ):
    print("\nProcessando:\n")
    arq_saida.write( '\t(\n' )
    for i in xrange( L ):
        arq_saida.write( '\t\t"' )
        print('\r'*3,end='N%'.replace('N','% 1.f' % (100*iteracao/float(L)) ));iteracao += 1
        for j in xrange( C ):
            
            arq_saida.write( "%d" % img[i][j] )
        if( i != (L-1) ): arq_saida.write( '",\n' )
        else:             arq_saida.write( '"\n\t);' )
    arq_saida.close()

elif( RGB_1D ):
    arq_saida.write( '\t(\n' )
    print("\nProcessando:\n")
    cores = []
    for i in xrange( L ):
        arq_saida.write( '\t\t( ' )
        print('\r'*3,end='N%'.replace('N','% 1.f' % (100*iteracao/float(L)) ));iteracao += 1
        for j in xrange( C ):
            cor = img[i][j]
            if( j != (C-1) ): arq_saida.write( "%d , " % cor )
            else:             arq_saida.write( "%d "   % cor )
            new_img[i][j] = cor
            if( not (cor in cores) ): cores.append( cor )
        if( i != (L-1) ): arq_saida.write( '),\n' )
        else:             arq_saida.write( ')\n\t);\n' )

    arq_saida.write( '\nMatriz de Cores:\n(\n' )
    for i in xrange( len( cores ) ):
        arq_saida.write( "( %d "   % cores[i] )
        if( i != ( len(cores)-1 ) ): arq_saida.write( '),\n' )
        else:             arq_saida.write( ')\n)\n' )
    arq_saida.close()
    print('\n%d Cores Identificadas.\n' % len(cores) )
    
    arq_saida.close()
    
elif( RGB_3D ):
    if( poucas_cores ):
        cores = []
        print("\nProcessando:\n")
        
        arq_saida.write( '\n\t(\n' )
        for i in xrange( L ):
            arq_saida.write( '\t\t(' )

            print('\r'*3,end='N%'.replace('N','% 1.f' % (100*iteracao/float(L)) ));iteracao += 1
            
            for j in xrange( C ):
                
                
                cor = list( img[i][j][:3] )
                if( cor == None ): raw_input("Erro")
                if( not (cor in cores) ): cores.append( cor )
                cor_indice = cores.index( cor )                
                if( j != (C-1) ): arq_saida.write( "%d, " % cor_indice )
                else:             arq_saida.write( "%d"   % cor_indice )
                new_img[i][j] = cor

            if( i != (L-1) ): arq_saida.write( '),\n' )
            else:             arq_saida.write( ')\n\t);\n' )

        arq_saida.write( '\nMatriz das %d Cores:\n\t(\n' % len(cores) )
        K = len( cores[0] )
        for i in xrange( len( cores ) ):
            arq_saida.write( '\t\t(' )
            for j in xrange( K ):
                if( j != (K-1) ): arq_saida.write( "%d, " % cores[i][j] )
                else:             arq_saida.write( "%d"   % cores[i][j] )
            if( i != ( len(cores)-1 ) ): arq_saida.write( '),\n' )
            else:             arq_saida.write( ')\n\t);\n' )
        arq_saida.close()
        print('\n%d Cores Identificadas.\n' % len(cores) )
    else:
        print("\nProcessando:\n")
        for cor in xrange( 3 ):
            if(   cor == 0 ): arq_saida.write(     'Matriz Vermelho:\n' )
            elif( cor == 1 ): arq_saida.write( '\n\nMatriz Verde:\n' )
            elif( cor == 2 ): arq_saida.write( '\n\nMatriz Azul:\n' )
            arq_saida.write( '\t(\n' )
            for i in xrange( L ):
                arq_saida.write( '\t\t(' )
                print('\r'*3,end='N%'.replace('N','% 1.f' % (100*iteracao/float(L*3)) ));iteracao += 1
                
                for j in xrange( C ):                    
                    if( j != (C-1) ): arq_saida.write( "%d, " % img[i][j][cor][:3] )
                    else:             arq_saida.write( "%d"   % img[i][j][cor][:3] )
                    new_img[i][j] = img[i][j]
                if( i != (L-1) ): arq_saida.write( '),\n' )
                else:             arq_saida.write( ')\n\t);\n' )
        arq_saida.close()
    
    
    
print ('\n\nArquivo "%s" foi criado na mesma pasta do algoritmo.' % arquivo.replace( arquivo[ ponto : ], ".txt" ) )

try:
    if( not RGB_1D ):
        if( input("\nInsira '1' caso deseje visualizar a img obtida: ") == 1 ):
            print('\n\nPreparando Representacao da Img Obtida.\n')
            teste( new_img )
            show()
except:
    None
