## 프로젝트 개요
C 컴파일러의 **의미 분석 단계**를 구현합니다.  
- 프로젝트 목표  
  - 각 변수/함수/구조체 이름이 올바르게 선언·사용되었는지 검사  
  - 타입 일치 여부 확인 (type checking)  
  - 재선언(re-declaration), 미선언(undeclared) 오류 검출  
  - 구조체 필드 접근, 포인터·배열·함수 호출의 의미적 오류 검출  

## 주요 기능
1. **Scoped Symbol Table**  
   - 블록 단위(scope)로 심볼 테이블 생성 및 관리  
   - 같은 이름의 변수라도 각기 다른 scope 허용  
2. **TypeInfo 및 ExtendedTypeInfo**  
   - 기본 타입(int, char, NULL)과 포인터·배열·구조체 타입 관리  
   - L-value 여부 정보 포함  
3. **Semantic Check List**  
   - 변수·함수 미선언 사용(undeclared)  
   - 중복 선언(re-declaration)  
   - 대입(assign) 시 LHS/LHS 타입 호환성  
   - 이항 연산, 비교 연산, 단항 연산 시 타입 검증  
   - 구조체 멤버 접근 (`.`/`->`), 배열 인덱싱(`[]`)  
4. **Function Declaration & Call Check**  
   - 매개변수 개수·타입 일치 여부  
   - 반환 타입(return type) 검사  
   ##  개발 환경 & 의존성
- **필수 도구**:  
  - GNU Flex (`flex`)  
  - GNU Bison (`bison`)  
  - GCC 또는 Clang (`gcc`/`clang`)  
- **라이브러리**:  
  - C 표준 라이브러리 (`<stdlib.h>`, `<string.h>` 등) 

##  빌드 및 실행 방법
1. **빌드**  
   ```bash
   cd project3/src
   make

2. **실행**
    '''bash
    ./subcc test.c