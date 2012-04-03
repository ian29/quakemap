Map { background-color:#222; }

@1: #fce4ae;
@2: #fcd68d;
@3: #ffc972;
@4: #ffaf5b;
@5: desaturate(#ff7a1d, 10);
@6: desaturate(#ff640a, 10);
@7: #f0540e;
@8: #ff4400;
@9: #ef2200;
@10: #de0100;


#psa03 {
  [zoom < 6] { line-width:0; }
  [zoom = 6] { line-width:.1; }
  [zoom = 7] { line-width:.15; }
  [zoom = 8] { line-width:.25; }
  [zoom = 9] { line-width:.5; }
  [zoom >= 10] { line-width:.75; }
  [GRID_CODE >= 0] { 
    polygon-opacity:.3; 
    polygon-fill:@1;
    line-color: darken(@1, 5);
  }
  [GRID_CODE >= 4] { 
    polygon-opacity:.3; 
    polygon-fill:@2;
    line-color: darken(@2, 5);
  }
  [GRID_CODE >= 8] { 
    polygon-opacity:.4; 
    polygon-fill:@3;
    line-color: darken(@3, 5);
  }
  [GRID_CODE >= 12] { 
    polygon-opacity:.5; 
    polygon-fill:@4;
    line-color: darken(@4, 5);
  }
  [GRID_CODE >= 16] { 
    polygon-opacity:.6; 
    polygon-fill:@5;
    line-color: darken(@5, 5);
  }
  [GRID_CODE >= 20] { 
    polygon-opacity:.7; 
    polygon-fill:@6;
    line-color: darken(@6, 5);
  }
  [GRID_CODE >= 24] { 
    polygon-opacity:.8; 
    polygon-fill:@7;
    line-color: darken(@7, 30);
  }
  [GRID_CODE >= 28] { 
    polygon-opacity:.9; 
    polygon-fill:@8;
    line-color: darken(@8, 20);
  }
  [GRID_CODE >= 32] { 
    polygon-opacity:1; 
    polygon-fill:@9;
    line-color: darken(@9, 10);
  }
  [GRID_CODE >= 34] { 
    polygon-opacity:1; 
    polygon-fill:@10;
    line-color: darken(@10, 10);
  } 
}
