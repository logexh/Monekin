import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';
import { IonicModule } from '@ionic/angular';
import { TranslateModule } from '@ngx-translate/core';
import { AppModule } from 'src/app/app.module';

import { CurrencyValueComponent } from './currency-value.component';

describe('CurrencyValueComponent', () => {
  let component: CurrencyValueComponent;
  let fixture: ComponentFixture<CurrencyValueComponent>;

  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      declarations: [CurrencyValueComponent],
      imports: [IonicModule.forRoot(), AppModule, TranslateModule],
    }).compileComponents();

    fixture = TestBed.createComponent(CurrencyValueComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  }));

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});